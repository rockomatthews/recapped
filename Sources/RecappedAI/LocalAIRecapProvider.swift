import Foundation
import RecappedCore

public final class LocalAIRecapProvider: AIRecapProvider, @unchecked Sendable {
    private let renderer: SlideshowVideoRenderer
    private let targetDuration: TimeInterval

    public init(
        renderer: SlideshowVideoRenderer = SlideshowVideoRenderer(),
        targetDuration: TimeInterval = 60
    ) {
        self.renderer = renderer
        self.targetDuration = targetDuration
    }

    public func generateRecap(for session: CapturedSession, outputURL: URL) async throws -> RecapResult {
        let selectedFrames = selectFrames(from: session.frames, limit: 24)
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

    private func selectFrames(from frames: [CaptureFrame], limit: Int) -> [CaptureFrame] {
        guard frames.count > limit else { return frames }

        var selected: [CaptureFrame] = []
        var seenApps = Set<String>()

        for frame in frames where selected.count < limit {
            let appName = frame.foregroundAppName ?? "Unknown"
            if !seenApps.contains(appName) || frame.reason != .fallbackInterval {
                selected.append(frame)
                seenApps.insert(appName)
            }
        }

        if selected.count < limit {
            let stride = Double(frames.count) / Double(limit)
            for index in 0..<limit where selected.count < limit {
                let frame = frames[min(frames.count - 1, Int(Double(index) * stride))]
                if !selected.contains(where: { $0.id == frame.id }) {
                    selected.append(frame)
                }
            }
        }

        return selected.sorted { $0.capturedAt < $1.capturedAt }
    }

    private func makeSummary(for session: CapturedSession, selectedFrames: [CaptureFrame]) -> String {
        let appNames = selectedFrames.compactMap(\.foregroundAppName)
        let uniqueApps = Array(NSOrderedSet(array: appNames)) as? [String] ?? []
        let appSummary = uniqueApps.isEmpty ? "the active workspace" : uniqueApps.prefix(4).joined(separator: ", ")
        return "Recapped \(selectedFrames.count) key moments from \(session.frames.count) captured frames across \(appSummary)."
    }
}
