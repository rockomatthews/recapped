import Foundation

public struct SupabaseUploadConfig: Equatable, Sendable {
    public let supabaseURL: URL
    public let publishableKey: String
    public let accessToken: String
    public let userID: String
    public let bucketName: String
    public let visibility: String

    public init(
        supabaseURL: URL,
        publishableKey: String,
        accessToken: String,
        userID: String,
        bucketName: String = "recapped-videos",
        visibility: String = "public"
    ) {
        self.supabaseURL = supabaseURL
        self.publishableKey = publishableKey
        self.accessToken = accessToken
        self.userID = userID
        self.bucketName = bucketName
        self.visibility = visibility
    }

    public static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> SupabaseUploadConfig? {
        guard
            let urlString = environment["RECAPPED_SUPABASE_URL"],
            let url = URL(string: urlString),
            let publishableKey = environment["RECAPPED_SUPABASE_PUBLISHABLE_KEY"],
            let accessToken = environment["RECAPPED_SUPABASE_ACCESS_TOKEN"],
            let userID = environment["RECAPPED_SUPABASE_USER_ID"]
        else {
            return nil
        }

        return SupabaseUploadConfig(
            supabaseURL: url,
            publishableKey: publishableKey,
            accessToken: accessToken,
            userID: userID,
            bucketName: environment["RECAPPED_SUPABASE_BUCKET"] ?? "recapped-videos",
            visibility: environment["RECAPPED_UPLOAD_VISIBILITY"] ?? "public"
        )
    }
}

public struct UploadedVideo: Equatable, Sendable {
    public let storagePath: String
    public let playbackURL: URL
}

public final class SupabaseVideoUploader: @unchecked Sendable {
    private let config: SupabaseUploadConfig
    private let session: URLSession

    public init(config: SupabaseUploadConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func upload(videoURL: URL, title: String, description: String?, durationSeconds: Int = 60) async throws -> UploadedVideo {
        let objectID = UUID().uuidString
        let storagePath = "\(config.userID)/\(objectID).mp4"
        let playbackURL = config.supabaseURL
            .appending(path: "storage/v1/object/public")
            .appending(path: config.bucketName)
            .appending(path: storagePath)

        try await uploadObject(videoURL: videoURL, storagePath: storagePath)
        try await insertVideoRow(
            title: title,
            description: description,
            storagePath: storagePath,
            playbackURL: playbackURL,
            durationSeconds: durationSeconds
        )

        return UploadedVideo(storagePath: storagePath, playbackURL: playbackURL)
    }

    private func uploadObject(videoURL: URL, storagePath: String) async throws {
        let uploadURL = config.supabaseURL
            .appending(path: "storage/v1/object")
            .appending(path: config.bucketName)
            .appending(path: storagePath)

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.setValue("false", forHTTPHeaderField: "x-upsert")
        request.httpBody = try Data(contentsOf: videoURL)

        try await send(request)
    }

    private func insertVideoRow(title: String, description: String?, storagePath: String, playbackURL: URL, durationSeconds: Int) async throws {
        let insertURL = config.supabaseURL.appending(path: "rest/v1/videos")
        let body: [String: Any?] = [
            "user_id": config.userID,
            "title": title,
            "description": description,
            "storage_path": storagePath,
            "playback_url": playbackURL.absoluteString,
            "duration_seconds": durationSeconds,
            "visibility": config.visibility
        ]

        var request = URLRequest(url: insertURL)
        request.httpMethod = "POST"
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

        try await send(request)
    }

    private func send(_ request: URLRequest) async throws {
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UploadError.requestFailed(httpResponse.statusCode)
        }
    }
}

public enum UploadError: LocalizedError, Equatable {
    case invalidResponse
    case requestFailed(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Upload failed because Supabase returned an invalid response."
        case .requestFailed(let statusCode):
            "Upload failed with Supabase status \(statusCode)."
        }
    }
}
