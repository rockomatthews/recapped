import Foundation
import Testing
@testable import RecappedCore

@Suite
struct CaptureSessionStateTests {
    @Test
    func appendsFramesOnlyWhileRecording() {
        let now = Date(timeIntervalSince1970: 100)
        let fileURL = URL(filePath: "/tmp/frame.png")
        let frame = CaptureFrame(
            capturedAt: now,
            reason: .manual,
            fileURL: fileURL,
            foregroundAppName: "Xcode"
        )

        var state = CaptureSessionState()
        #expect(state.appendFrame(frame) == false)

        state.start(at: now)
        #expect(state.appendFrame(frame) == true)
        #expect(state.frames.count == 1)

        state.pause()
        #expect(state.appendFrame(frame) == false)

        state.resume()
        #expect(state.appendFrame(frame) == true)

        state.stop(at: now.addingTimeInterval(10))
        #expect(state.appendFrame(frame) == false)
    }
}
