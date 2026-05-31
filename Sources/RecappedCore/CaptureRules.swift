import Foundation

public struct CaptureRules: Equatable, Sendable {
    public var minimumSecondsBetweenCaptures: TimeInterval
    public var fallbackCaptureInterval: TimeInterval
    public var maximumFramesPerSession: Int

    public init(
        minimumSecondsBetweenCaptures: TimeInterval = 3,
        fallbackCaptureInterval: TimeInterval = 15,
        maximumFramesPerSession: Int = 2_000
    ) {
        self.minimumSecondsBetweenCaptures = minimumSecondsBetweenCaptures
        self.fallbackCaptureInterval = fallbackCaptureInterval
        self.maximumFramesPerSession = maximumFramesPerSession
    }
}
