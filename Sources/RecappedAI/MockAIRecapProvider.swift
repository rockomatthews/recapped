import Foundation
import RecappedCore

public final class MockAIRecapProvider: AIRecapProvider, @unchecked Sendable {
    public init() {}

    public func generateRecap(for session: CapturedSession, outputURL: URL) async throws -> RecapResult {
        let payload = "Mock 60-second recap for session \(session.id.uuidString)"
        try payload.data(using: .utf8)?.write(to: outputURL, options: [.atomic])
        return RecapResult(
            sessionID: session.id,
            videoURL: outputURL,
            summary: "Mock recap generated from \(session.frames.count) frame(s).",
            durationSeconds: 60
        )
    }
}
