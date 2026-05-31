import Foundation

public enum CaptureReason: String, Codable, Equatable, Sendable {
    case appChanged
    case fallbackInterval
    case manual
    case sessionStarted
}

public struct CaptureFrame: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let capturedAt: Date
    public let reason: CaptureReason
    public let fileURL: URL
    public let foregroundAppName: String?

    public init(
        id: UUID = UUID(),
        capturedAt: Date,
        reason: CaptureReason,
        fileURL: URL,
        foregroundAppName: String?
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.reason = reason
        self.fileURL = fileURL
        self.foregroundAppName = foregroundAppName
    }
}

public struct ActivitySample: Equatable, Sendable {
    public let sampledAt: Date
    public let foregroundAppName: String?

    public init(sampledAt: Date, foregroundAppName: String?) {
        self.sampledAt = sampledAt
        self.foregroundAppName = foregroundAppName
    }
}

public struct CaptureSessionState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public private(set) var startedAt: Date?
    public private(set) var stoppedAt: Date?
    public private(set) var isPaused: Bool
    public private(set) var frames: [CaptureFrame]
    public var rules: CaptureRules

    public init(
        id: UUID = UUID(),
        startedAt: Date? = nil,
        stoppedAt: Date? = nil,
        isPaused: Bool = false,
        frames: [CaptureFrame] = [],
        rules: CaptureRules = CaptureRules()
    ) {
        self.id = id
        self.startedAt = startedAt
        self.stoppedAt = stoppedAt
        self.isPaused = isPaused
        self.frames = frames
        self.rules = rules
    }

    public var isRecording: Bool {
        startedAt != nil && stoppedAt == nil && !isPaused
    }

    public var hasStopped: Bool {
        stoppedAt != nil
    }

    public mutating func start(at date: Date) {
        guard startedAt == nil else { return }
        startedAt = date
        stoppedAt = nil
        isPaused = false
    }

    public mutating func pause() {
        guard startedAt != nil, stoppedAt == nil else { return }
        isPaused = true
    }

    public mutating func resume() {
        guard startedAt != nil, stoppedAt == nil else { return }
        isPaused = false
    }

    public mutating func stop(at date: Date) {
        guard startedAt != nil, stoppedAt == nil else { return }
        stoppedAt = date
        isPaused = false
    }

    @discardableResult
    public mutating func appendFrame(_ frame: CaptureFrame) -> Bool {
        guard isRecording, frames.count < rules.maximumFramesPerSession else {
            return false
        }
        frames.append(frame)
        return true
    }
}
