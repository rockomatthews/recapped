import Foundation

public struct SiteUploadConfig: Equatable, Sendable {
    public let webBaseURL: URL
    public let pairingCode: String

    public init(webBaseURL: URL, pairingCode: String) {
        self.webBaseURL = webBaseURL
        self.pairingCode = pairingCode
    }

    public static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> SiteUploadConfig? {
        guard
            let webURLString = environment["RECAPPED_WEB_URL"],
            let webBaseURL = URL(string: webURLString),
            let pairingCode = environment["RECAPPED_PAIRING_CODE"],
            !pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return SiteUploadConfig(webBaseURL: webBaseURL, pairingCode: pairingCode)
    }
}

public struct UploadedVideo: Equatable, Sendable {
    public let storagePath: String
    public let playbackURL: URL
}

public final class SiteVideoUploader: @unchecked Sendable {
    private let config: SiteUploadConfig
    private let session: URLSession

    public init(config: SiteUploadConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    public func upload(videoURL: URL, title: String, description: String?, durationSeconds: Int = 60) async throws -> UploadedVideo {
        let boundary = "RecappedBoundary-\(UUID().uuidString)"
        let uploadURL = config.webBaseURL.appending(path: "api/desktop/upload")
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeBody(
            boundary: boundary,
            videoURL: videoURL,
            title: title,
            description: description,
            durationSeconds: durationSeconds
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw UploadError.requestFailed(httpResponse.statusCode, message)
        }

        let payload = try JSONDecoder().decode(UploadResponse.self, from: data)
        guard let playbackURL = URL(string: payload.playbackURL) else {
            throw UploadError.invalidResponse
        }

        return UploadedVideo(storagePath: payload.storagePath, playbackURL: playbackURL)
    }

    private func makeBody(boundary: String, videoURL: URL, title: String, description: String?, durationSeconds: Int) throws -> Data {
        var data = Data()
        appendField(name: "code", value: config.pairingCode, boundary: boundary, to: &data)
        appendField(name: "title", value: title, boundary: boundary, to: &data)
        appendField(name: "description", value: description ?? "", boundary: boundary, to: &data)
        appendField(name: "durationSeconds", value: "\(durationSeconds)", boundary: boundary, to: &data)
        try appendFile(name: "video", fileName: "recap.mp4", mimeType: "video/mp4", fileURL: videoURL, boundary: boundary, to: &data)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }

    private func appendField(name: String, value: String, boundary: String, to data: inout Data) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }

    private func appendFile(name: String, fileName: String, mimeType: String, fileURL: URL, boundary: String, to data: inout Data) throws {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: fileURL))
        data.append("\r\n".data(using: .utf8)!)
    }
}

private struct UploadResponse: Decodable {
    let storagePath: String
    let playbackURL: String
}

public enum UploadError: LocalizedError, Equatable {
    case invalidResponse
    case requestFailed(Int, String?)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Upload failed because Recapped returned an invalid response."
        case .requestFailed(let statusCode, let message):
            "Upload failed with Recapped status \(statusCode): \(message ?? "No details")"
        }
    }
}
