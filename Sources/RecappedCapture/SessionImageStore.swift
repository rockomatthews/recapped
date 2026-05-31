import Foundation
import RecappedCore

public final class SessionImageStore: @unchecked Sendable {
    private let rootURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder

    public init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
    }

    public static func defaultStore(fileManager: FileManager = .default) throws -> SessionImageStore {
        let baseURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let rootURL = baseURL.appending(path: "Recapped/Sessions", directoryHint: .isDirectory)
        return SessionImageStore(rootURL: rootURL, fileManager: fileManager)
    }

    public func prepareSessionDirectory(sessionID: UUID) throws -> URL {
        let url = sessionDirectoryURL(sessionID: sessionID)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public func frameURL(sessionID: UUID, frameID: UUID) throws -> URL {
        let sessionURL = try prepareSessionDirectory(sessionID: sessionID)
        return sessionURL.appending(path: "\(frameID.uuidString).png")
    }

    @discardableResult
    public func writeMetadata(for session: CapturedSession) throws -> URL {
        let sessionURL = try prepareSessionDirectory(sessionID: session.id)
        let metadataURL = sessionURL.appending(path: "session.json")
        let data = try encoder.encode(session)
        try data.write(to: metadataURL, options: [.atomic])
        return metadataURL
    }

    public func recapVideoURL(sessionID: UUID) throws -> URL {
        let sessionURL = try prepareSessionDirectory(sessionID: sessionID)
        return sessionURL.appending(path: "recap.mp4")
    }

    private func sessionDirectoryURL(sessionID: UUID) -> URL {
        rootURL.appending(path: sessionID.uuidString, directoryHint: .isDirectory)
    }
}
