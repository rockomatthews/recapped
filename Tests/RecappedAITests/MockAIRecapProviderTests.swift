import Foundation
import Testing
import RecappedAI
import RecappedCore

@Suite
struct MockAIRecapProviderTests {
    @Test
    func mockProviderCreatesSixtySecondRecapArtifact() async throws {
        let provider = MockAIRecapProvider()
        let outputURL = FileManager.default.temporaryDirectory
            .appending(path: "recapped-mock-\(UUID().uuidString).mp4")
        let frame = CaptureFrame(
            capturedAt: Date(timeIntervalSince1970: 500),
            reason: .manual,
            fileURL: URL(filePath: "/tmp/frame.png"),
            foregroundAppName: "Xcode"
        )
        let session = CapturedSession(
            id: UUID(),
            startedAt: Date(timeIntervalSince1970: 500),
            stoppedAt: Date(timeIntervalSince1970: 560),
            frames: [frame]
        )

        let result = try await provider.generateRecap(for: session, outputURL: outputURL)

        #expect(result.durationSeconds == 60)
        #expect(FileManager.default.fileExists(atPath: outputURL.path))
        try? FileManager.default.removeItem(at: outputURL)
    }
}
