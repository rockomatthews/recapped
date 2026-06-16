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

    @Test
    func excludesFramesMarkedSensitive() {
        let selector = RecapFrameSelector()
        let start = Date(timeIntervalSince1970: 3_000)
        let sensitiveFrame = CaptureFrame(
            capturedAt: start,
            reason: .appChanged,
            fileURL: URL(filePath: "/tmp/sensitive.png"),
            foregroundAppName: "Terminal"
        )
        let safeFrame = CaptureFrame(
            capturedAt: start.addingTimeInterval(1),
            reason: .fallbackInterval,
            fileURL: URL(filePath: "/tmp/safe.png"),
            foregroundAppName: "Xcode"
        )
        let evaluations = [
            sensitiveFrame.id: SnapEvaluation(
                frameID: sensitiveFrame.id,
                qualityScore: 99,
                containsSensitiveText: true,
                reasons: ["private key detected"]
            )
        ]

        let selected = selector.selectFrames(
            from: [sensitiveFrame, safeFrame],
            targetCount: 2,
            evaluations: evaluations
        )

        #expect(selected == [safeFrame])
    }

    @Test
    func secretDetectorFlagsPrivateKeyMaterial() {
        let detector = SecretDetector()
        let matches = detector.matches(in: "-----BEGIN PRIVATE KEY-----\nabc123\n-----END PRIVATE KEY-----")

        #expect(matches.contains("private key detected"))
    }
}
