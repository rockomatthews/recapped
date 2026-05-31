import Foundation

public struct CapturedSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let stoppedAt: Date
    public let frames: [CaptureFrame]
    public let metadataURL: URL?

    public init(
        id: UUID,
        startedAt: Date,
        stoppedAt: Date,
        frames: [CaptureFrame],
        metadataURL: URL? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.stoppedAt = stoppedAt
        self.frames = frames
        self.metadataURL = metadataURL
    }
}

public struct RecapResult: Codable, Equatable, Sendable {
    public let sessionID: UUID
    public let videoURL: URL
    public let summary: String
    public let durationSeconds: TimeInterval

    public init(
        sessionID: UUID,
        videoURL: URL,
        summary: String,
        durationSeconds: TimeInterval
    ) {
        self.sessionID = sessionID
        self.videoURL = videoURL
        self.summary = summary
        self.durationSeconds = durationSeconds
    }
}
