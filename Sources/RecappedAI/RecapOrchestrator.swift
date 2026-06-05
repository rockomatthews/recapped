import Foundation
import RecappedCore

public final class RecapOrchestrator: @unchecked Sendable {
    private let provider: AIRecapProvider

    public init(provider: AIRecapProvider) {
        self.provider = provider
    }

    public func renderOneMinuteRecap(
        for session: CapturedSession,
        outputURL: URL
    ) async throws -> RecapResult {
        try await provider.generateRecap(for: session, outputURL: outputURL)
    }
}
