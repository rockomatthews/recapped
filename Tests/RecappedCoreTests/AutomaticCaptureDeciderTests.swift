import Foundation
import Testing
@testable import RecappedCore

@Suite
struct AutomaticCaptureDeciderTests {
    @Test
    func capturesAtSessionStart() {
        let now = Date(timeIntervalSince1970: 200)
        var state = CaptureSessionState()
        state.start(at: now)
        var decider = AutomaticCaptureDecider()

        let decision = decider.evaluate(
            sample: ActivitySample(sampledAt: now, foregroundAppName: "Xcode"),
            session: state
        )

        #expect(decision?.reason == .sessionStarted)
    }

    @Test
    func capturesWhenForegroundAppChangesAfterMinimumInterval() {
        let start = Date(timeIntervalSince1970: 300)
        let rules = CaptureRules(minimumSecondsBetweenCaptures: 3, fallbackCaptureInterval: 30)
        var state = CaptureSessionState(rules: rules)
        state.start(at: start)
        var decider = AutomaticCaptureDecider()
        decider.markCaptured(at: start, foregroundAppName: "Safari")

        let decision = decider.evaluate(
            sample: ActivitySample(sampledAt: start.addingTimeInterval(4), foregroundAppName: "Xcode"),
            session: state
        )

        #expect(decision?.reason == .appChanged)
    }

    @Test
    func capturesAtFallbackInterval() {
        let start = Date(timeIntervalSince1970: 400)
        let rules = CaptureRules(minimumSecondsBetweenCaptures: 3, fallbackCaptureInterval: 15)
        var state = CaptureSessionState(rules: rules)
        state.start(at: start)
        var decider = AutomaticCaptureDecider()
        decider.markCaptured(at: start, foregroundAppName: "Xcode")

        let decision = decider.evaluate(
            sample: ActivitySample(sampledAt: start.addingTimeInterval(16), foregroundAppName: "Xcode"),
            session: state
        )

        #expect(decision?.reason == .fallbackInterval)
    }

    @Test
    func capturesRecentInputAfterActivityInterval() {
        let start = Date(timeIntervalSince1970: 500)
        let rules = CaptureRules(
            minimumSecondsBetweenCaptures: 3,
            activeInputCaptureInterval: 8,
            fallbackCaptureInterval: 30
        )
        var state = CaptureSessionState(rules: rules)
        state.start(at: start)
        var decider = AutomaticCaptureDecider()
        decider.markCaptured(at: start, foregroundAppName: "Xcode")

        let decision = decider.evaluate(
            sample: ActivitySample(
                sampledAt: start.addingTimeInterval(9),
                foregroundAppName: "Xcode",
                secondsSinceLastInput: 0.4
            ),
            session: state
        )

        #expect(decision?.reason == .userActivity)
    }

    @Test
    func skipsExcludedForegroundApps() {
        let start = Date(timeIntervalSince1970: 600)
        var state = CaptureSessionState()
        state.start(at: start)
        var decider = AutomaticCaptureDecider()

        let decision = decider.evaluate(
            sample: ActivitySample(sampledAt: start, foregroundAppName: "1Password"),
            session: state
        )

        #expect(decision == nil)
    }
}
