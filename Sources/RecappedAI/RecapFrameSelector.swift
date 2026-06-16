import Foundation
import RecappedCore

public struct RecapFrameSelector: Sendable {
    public init() {}

    public func selectFrames(
        from frames: [CaptureFrame],
        targetCount: Int = 60,
        evaluations: [UUID: SnapEvaluation] = [:]
    ) -> [CaptureFrame] {
        let sortedFrames = frames
            .filter { evaluations[$0.id]?.containsSensitiveText != true }
            .sorted { $0.capturedAt < $1.capturedAt }
        guard targetCount > 0, sortedFrames.count > targetCount else {
            return sortedFrames
        }

        let appCounts = Dictionary(grouping: sortedFrames, by: { $0.foregroundAppName ?? "Unknown" })
            .mapValues(\.count)
        let scoredFrames = sortedFrames.enumerated().map { index, frame in
            ScoredFrame(
                frame: frame,
                score: score(
                    frame: frame,
                    index: index,
                    sortedFrames: sortedFrames,
                    appCounts: appCounts,
                    evaluation: evaluations[frame.id]
                )
            )
        }

        var selectedByID: [UUID: ScoredFrame] = [:]
        let bucketCount = min(targetCount, sortedFrames.count)

        for bucketIndex in 0..<bucketCount {
            let start = Int((Double(bucketIndex) / Double(bucketCount)) * Double(scoredFrames.count))
            let end = max(
                start + 1,
                Int((Double(bucketIndex + 1) / Double(bucketCount)) * Double(scoredFrames.count))
            )
            let bucket = scoredFrames[start..<min(end, scoredFrames.count)]
            if let best = bucket.max(by: { $0.score < $1.score }) {
                selectedByID[best.frame.id] = best
            }
        }

        forceInclude(scoredFrames.first, in: &selectedByID, targetCount: targetCount)
        forceInclude(scoredFrames.last, in: &selectedByID, targetCount: targetCount)

        if selectedByID.count < targetCount {
            for scoredFrame in scoredFrames.sorted(by: { $0.score > $1.score }) {
                selectedByID[scoredFrame.frame.id] = scoredFrame
                if selectedByID.count == targetCount {
                    break
                }
            }
        }

        return selectedByID.values
            .map(\.frame)
            .sorted { $0.capturedAt < $1.capturedAt }
    }

    private func forceInclude(
        _ scoredFrame: ScoredFrame?,
        in selectedByID: inout [UUID: ScoredFrame],
        targetCount: Int
    ) {
        guard let scoredFrame, selectedByID[scoredFrame.frame.id] == nil else {
            return
        }

        if selectedByID.count >= targetCount,
           let weakest = selectedByID.values.min(by: { $0.score < $1.score }) {
            selectedByID.removeValue(forKey: weakest.frame.id)
        }

        selectedByID[scoredFrame.frame.id] = scoredFrame
    }

    private func score(
        frame: CaptureFrame,
        index: Int,
        sortedFrames: [CaptureFrame],
        appCounts: [String: Int],
        evaluation: SnapEvaluation?
    ) -> Double {
        var score = reasonScore(frame.reason)
        let appName = frame.foregroundAppName ?? "Unknown"
        let appCount = max(1, appCounts[appName] ?? 1)

        score += evaluation?.qualityScore ?? 0
        score += min(3, log(Double(sortedFrames.count) / Double(appCount) + 1))

        if index > 0 {
            let previous = sortedFrames[index - 1]
            if previous.foregroundAppName != frame.foregroundAppName {
                score += 2.5
            }
        }

        if index + 1 < sortedFrames.count {
            let next = sortedFrames[index + 1]
            if next.foregroundAppName != frame.foregroundAppName {
                score += 1.25
            }
        }

        if frame.reason != .fallbackInterval {
            score += 1
        }

        return score
    }

    private func reasonScore(_ reason: CaptureReason) -> Double {
        switch reason {
        case .appChanged:
            6
        case .userActivity:
            5
        case .sessionStarted:
            3
        case .manual:
            2
        case .fallbackInterval:
            1
        }
    }
}

private struct ScoredFrame: Sendable {
    let frame: CaptureFrame
    let score: Double
}
