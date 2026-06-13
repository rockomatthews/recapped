import Foundation
import Testing
import RecappedAI
import RecappedCore

@Suite
struct RecapFrameSelectorTests {
    @Test
    func selectsMomentsAcrossTheWholeSessionInsteadOfOnlyTheBeginning() {
        let selector = RecapFrameSelector()
        let start = Date(timeIntervalSince1970: 1_000)
        let frames = (0..<180).map { index in
            CaptureFrame(
                id: UUID(),
                capturedAt: start.addingTimeInterval(TimeInterval(index * 60)),
                reason: index > 140 ? .appChanged : .fallbackInterval,
                fileURL: URL(filePath: "/tmp/frame-\(index).png"),
                foregroundAppName: index > 140 ? "Final Cut Pro" : "Chrome"
            )
        }

        let selected = selector.selectFrames(from: frames, targetCount: 30)

        #expect(selected.count == 30)
        #expect(selected.contains { $0.capturedAt >= start.addingTimeInterval(140 * 60) })
        #expect(selected.last?.capturedAt == frames.last?.capturedAt)
    }

    @Test
    func returnsFramesInChronologicalOrder() {
        let selector = RecapFrameSelector()
        let start = Date(timeIntervalSince1970: 2_000)
        let frames = (0..<90).reversed().map { index in
            CaptureFrame(
                id: UUID(),
                capturedAt: start.addingTimeInterval(TimeInterval(index)),
                reason: index.isMultiple(of: 10) ? .userActivity : .fallbackInterval,
                fileURL: URL(filePath: "/tmp/frame-\(index).png"),
                foregroundAppName: "Xcode"
            )
        }

        let selected = selector.selectFrames(from: frames, targetCount: 20)

        #expect(selected == selected.sorted { $0.capturedAt < $1.capturedAt })
    }
}
