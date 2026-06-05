import AppKit
import CoreGraphics
import Foundation
import RecappedCore

public final class MacActivitySampler: ActivitySampling, @unchecked Sendable {
    public init() {}

    public func sample() -> ActivitySample {
        ActivitySample(
            sampledAt: Date(),
            foregroundAppName: NSWorkspace.shared.frontmostApplication?.localizedName,
            secondsSinceLastInput: secondsSinceLastInput()
        )
    }

    private func secondsSinceLastInput() -> TimeInterval? {
        let stateID = CGEventSourceStateID.combinedSessionState
        let eventTypes: [CGEventType] = [
            .keyDown,
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown,
            .mouseMoved,
            .scrollWheel
        ]

        let seconds = eventTypes
            .map { CGEventSource.secondsSinceLastEventType(stateID, eventType: $0) }
            .filter { $0 >= 0 }
            .min()

        return seconds
    }
}
