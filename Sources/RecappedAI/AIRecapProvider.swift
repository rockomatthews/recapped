import Foundation
import RecappedCore

public protocol AIRecapProvider: Sendable {
    func generateRecap(for session: CapturedSession, outputURL: URL) async throws -> RecapResult
}
