import Foundation

public struct CaptureRules: Equatable, Sendable {
    public var minimumSecondsBetweenCaptures: TimeInterval
    public var activeInputCaptureInterval: TimeInterval
    public var fallbackCaptureInterval: TimeInterval
    public var maximumFramesPerSession: Int
    public var activeInputThreshold: TimeInterval
    public var excludedForegroundAppNames: Set<String>

    public init(
        minimumSecondsBetweenCaptures: TimeInterval = 3,
        activeInputCaptureInterval: TimeInterval = 8,
        fallbackCaptureInterval: TimeInterval = 15,
        maximumFramesPerSession: Int = 2_000,
        activeInputThreshold: TimeInterval = 2,
        excludedForegroundAppNames: Set<String> = [
            "1password",
            "bitwarden",
            "dashlane",
            "keychain access"
        ]
    ) {
        self.minimumSecondsBetweenCaptures = minimumSecondsBetweenCaptures
        self.activeInputCaptureInterval = activeInputCaptureInterval
        self.fallbackCaptureInterval = fallbackCaptureInterval
        self.maximumFramesPerSession = maximumFramesPerSession
        self.activeInputThreshold = activeInputThreshold
        self.excludedForegroundAppNames = excludedForegroundAppNames
    }

    public func allowsCapture(for sample: ActivitySample) -> Bool {
        guard let foregroundAppName = sample.foregroundAppName?.lowercased() else {
            return true
        }
        return !excludedForegroundAppNames.contains(foregroundAppName)
    }
}
