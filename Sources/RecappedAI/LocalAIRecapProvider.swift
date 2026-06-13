import Foundation
import RecappedCore

public final class LocalAIRecapProvider: AIRecapProvider, @unchecked Sendable {
    private let renderer: SlideshowVideoRenderer
    private let selector: RecapFrameSelector
    private let targetDuration: TimeInterval

    public init(
        renderer: SlideshowVideoRenderer = SlideshowVideoRenderer(),
        selector: RecapFrameSelector = RecapFrameSelector(),
        targetDuration: TimeInterval = 60
    ) {
        self.renderer = renderer
        self.selector = selector
        self.targetDuration = targetDuration
    }

    public func generateRecap(for session: CapturedSession, outputURL: URL) async throws -> RecapResult {
        let selectedFrames = selector.selectFrames(
            from: session.frames,
            targetCount: Int(targetDuration.rounded())
        )
        try await renderer.render(
            frames: selectedFrames,
            outputURL: outputURL,
            durationSeconds: targetDuration
        )

        return RecapResult(
            sessionID: session.id,
            videoURL: outputURL,
            summary: makeSummary(for: session, selectedFrames: selectedFrames),
            durationSeconds: targetDuration
        )
    }

    private func makeSummary(for session: CapturedSession, selectedFrames: [CaptureFrame]) -> String {
        let appNames = selectedFrames.compactMap(\.foregroundAppName)
        let uniqueApps = Array(NSOrderedSet(array: appNames)) as? [String] ?? []
        let appSummary = uniqueApps.isEmpty ? "the active workspace" : uniqueApps.prefix(4).joined(separator: ", ")
        return "Recapped \(selectedFrames.count) key moments from \(session.frames.count) captured frames across \(appSummary)."
    }
}
