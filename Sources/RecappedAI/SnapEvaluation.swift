import Foundation
import RecappedCore
import Vision

public struct SnapEvaluation: Equatable, Sendable {
    public let frameID: UUID
    public let qualityScore: Double
    public let containsSensitiveText: Bool
    public let reasons: [String]

    public init(frameID: UUID, qualityScore: Double, containsSensitiveText: Bool, reasons: [String]) {
        self.frameID = frameID
        self.qualityScore = qualityScore
        self.containsSensitiveText = containsSensitiveText
        self.reasons = reasons
    }
}

public final class SnapEvaluator: @unchecked Sendable {
    private let secretDetector: SecretDetector

    public init(secretDetector: SecretDetector = SecretDetector()) {
        self.secretDetector = secretDetector
    }

    public func evaluate(frames: [CaptureFrame]) async -> [UUID: SnapEvaluation] {
        var evaluations: [UUID: SnapEvaluation] = [:]
        for frame in frames {
            evaluations[frame.id] = await evaluate(frame: frame)
        }
        return evaluations
    }

    public func evaluate(frame: CaptureFrame) async -> SnapEvaluation {
        let recognizedText = recognizeText(in: frame.fileURL)
        let secretMatches = secretDetector.matches(in: recognizedText)
        let wordCount = recognizedText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        var qualityScore = reasonScore(frame.reason)
        var reasons = [displayName(for: frame.reason)]

        if wordCount > 8 {
            qualityScore += min(3, Double(wordCount) / 80)
            reasons.append("readable work surface")
        }

        if frame.foregroundAppName != nil {
            qualityScore += 0.5
        }

        if !secretMatches.isEmpty {
            qualityScore = 0
            reasons.append(contentsOf: secretMatches)
        }

        return SnapEvaluation(
            frameID: frame.id,
            qualityScore: qualityScore,
            containsSensitiveText: !secretMatches.isEmpty,
            reasons: reasons
        )
    }

    private func recognizeText(in imageURL: URL) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(url: imageURL)
        do {
            try handler.perform([request])
        } catch {
            return ""
        }

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
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

    private func displayName(for reason: CaptureReason) -> String {
        switch reason {
        case .appChanged:
            "app changed"
        case .userActivity:
            "active work"
        case .sessionStarted:
            "session started"
        case .manual:
            "manual capture"
        case .fallbackInterval:
            "progress checkpoint"
        }
    }
}

public struct SecretDetector: Sendable {
    private let patterns: [SecretPattern]

    public init(patterns: [SecretPattern] = SecretPattern.defaults) {
        self.patterns = patterns
    }

    public func matches(in text: String) -> [String] {
        patterns.compactMap { pattern in
            pattern.matches(text) ? pattern.reason : nil
        }
    }
}

public struct SecretPattern: Sendable {
    public let reason: String
    private let expression: NSRegularExpression

    public init(reason: String, pattern: String) {
        self.reason = reason
        self.expression = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    public func matches(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.firstMatch(in: text, range: range) != nil
    }

    public static let defaults: [SecretPattern] = [
        SecretPattern(reason: "private key detected", pattern: #"-----BEGIN [A-Z ]*PRIVATE KEY-----"#),
        SecretPattern(reason: "AWS access key detected", pattern: #"\bAKIA[0-9A-Z]{16}\b"#),
        SecretPattern(reason: "OpenAI-style API key detected", pattern: #"\bsk-[A-Za-z0-9_\-]{20,}\b"#),
        SecretPattern(reason: "Slack token detected", pattern: #"\bxox[baprs]-[A-Za-z0-9\-]{20,}\b"#),
        SecretPattern(reason: "service role key detected", pattern: #"\b(service[_ -]?role|SUPABASE_SERVICE_ROLE_KEY)\b"#),
        SecretPattern(reason: "secret access key detected", pattern: #"\b(secret[_ -]?access[_ -]?key|private[_ -]?key|api[_ -]?secret)\b"#)
    ]
}
