import Foundation

public struct CaptureDecision: Equatable, Sendable {
    public let reason: CaptureReason
    public let sampledAt: Date

    public init(reason: CaptureReason, sampledAt: Date) {
        self.reason = reason
        self.sampledAt = sampledAt
    }
}

public struct AutomaticCaptureDecider: Sendable {
    private var lastCaptureAt: Date?
    private var lastForegroundAppName: String?

    public init() {}

    public mutating func reset() {
        lastCaptureAt = nil
        lastForegroundAppName = nil
    }

    public mutating func markCaptured(at date: Date, foregroundAppName: String?) {
        lastCaptureAt = date
        lastForegroundAppName = foregroundAppName
    }

    public mutating func evaluate(
        sample: ActivitySample,
        session: CaptureSessionState
    ) -> CaptureDecision? {
        guard session.isRecording else { return nil }
        guard session.frames.count < session.rules.maximumFramesPerSession else { return nil }

        if lastCaptureAt == nil {
            return CaptureDecision(reason: .sessionStarted, sampledAt: sample.sampledAt)
        }

        guard let lastCaptureAt else {
            return CaptureDecision(reason: .sessionStarted, sampledAt: sample.sampledAt)
        }

        let secondsSinceCapture = sample.sampledAt.timeIntervalSince(lastCaptureAt)
        guard secondsSinceCapture >= session.rules.minimumSecondsBetweenCaptures else {
            return nil
        }

        if sample.foregroundAppName != lastForegroundAppName {
            return CaptureDecision(reason: .appChanged, sampledAt: sample.sampledAt)
        }

        if secondsSinceCapture >= session.rules.fallbackCaptureInterval {
            return CaptureDecision(reason: .fallbackInterval, sampledAt: sample.sampledAt)
        }

        return nil
    }
}
