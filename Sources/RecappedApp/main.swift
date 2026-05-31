import SwiftUI
import RecappedAI
import RecappedCapture
import RecappedCore

@main
struct RecappedApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 720, minHeight: 520)
        }
    }
}

struct ContentView: View {
    @StateObject private var model = SessionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recapped")
                        .font(.largeTitle.bold())
                    Text(model.statusText)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.isRecording {
                    Button("Stop") {
                        Task { await model.stop() }
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Start") {
                        Task { await model.start() }
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow {
                    metric("Frames", value: "\(model.frameCount)")
                    metric("Backend", value: model.backendName)
                    metric("Recap", value: model.recapState)
                }
            }

            if let result = model.lastResult {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest recap")
                        .font(.headline)
                    Text(result.summary)
                    Text(result.videoURL.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Spacer()

            Text("Screenshots are captured automatically after Start and written locally. Recap generation begins when Stop is pressed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var frameCount = 0
    @Published private(set) var isRecording = false
    @Published private(set) var recapState = "Idle"
    @Published private(set) var statusText = "Ready to capture a work session."
    @Published private(set) var lastResult: RecapResult?

    let backendName = CaptureBackend.defaultBackend.rawValue

    private var state = CaptureSessionState()
    private var decider = AutomaticCaptureDecider()
    private var timer: Timer?
    private let capturer = CoreGraphicsScreenshotCapturer()
    private let aiProvider = LocalAIRecapProvider()
    private var store: SessionImageStore?

    func start() async {
        guard !isRecording else { return }

        do {
            store = try SessionImageStore.defaultStore()
            state = CaptureSessionState()
            state.start(at: Date())
            decider.reset()
            frameCount = 0
            lastResult = nil
            recapState = "Recording"
            statusText = "Recording automatically. Switch apps or keep working to create frames."
            isRecording = true
            scheduleCaptureTimer()
            await captureIfNeeded(forceReason: .manual)
        } catch {
            statusText = "Could not start: \(error.localizedDescription)"
        }
    }

    func stop() async {
        guard isRecording else { return }
        timer?.invalidate()
        timer = nil
        state.stop(at: Date())
        isRecording = false
        recapState = "Rendering"
        statusText = "Rendering a 60-second AI recap from \(state.frames.count) frame(s)."

        guard
            let startedAt = state.startedAt,
            let stoppedAt = state.stoppedAt,
            let store
        else {
            recapState = "Idle"
            return
        }

        do {
            var capturedSession = CapturedSession(
                id: state.id,
                startedAt: startedAt,
                stoppedAt: stoppedAt,
                frames: state.frames
            )
            let metadataURL = try store.writeMetadata(for: capturedSession)
            capturedSession = CapturedSession(
                id: capturedSession.id,
                startedAt: capturedSession.startedAt,
                stoppedAt: capturedSession.stoppedAt,
                frames: capturedSession.frames,
                metadataURL: metadataURL
            )
            let outputURL = try store.recapVideoURL(sessionID: capturedSession.id)
            let result = try await aiProvider.generateRecap(for: capturedSession, outputURL: outputURL)
            lastResult = result
            recapState = "Done"
            statusText = "Recap complete."
        } catch {
            recapState = "Failed"
            statusText = "Recap failed: \(error.localizedDescription)"
        }
    }

    private func scheduleCaptureTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.captureIfNeeded(forceReason: nil)
            }
        }
    }

    private func captureIfNeeded(forceReason: CaptureReason?) async {
        guard let store else { return }

        let sample = ActivitySample(
            sampledAt: Date(),
            foregroundAppName: NSWorkspace.shared.frontmostApplication?.localizedName
        )
        let decision: CaptureDecision?

        if let forceReason {
            decision = CaptureDecision(reason: forceReason, sampledAt: sample.sampledAt)
        } else {
            decision = decider.evaluate(sample: sample, session: state)
        }

        guard let decision else { return }

        do {
            let frameID = UUID()
            let fileURL = try store.frameURL(sessionID: state.id, frameID: frameID)
            let savedURL = try capturer.captureScreenshot(to: fileURL)
            let frame = CaptureFrame(
                id: frameID,
                capturedAt: decision.sampledAt,
                reason: decision.reason,
                fileURL: savedURL,
                foregroundAppName: sample.foregroundAppName
            )
            if state.appendFrame(frame) {
                decider.markCaptured(at: decision.sampledAt, foregroundAppName: sample.foregroundAppName)
                frameCount = state.frames.count
            }
        } catch {
            statusText = "Capture failed: \(error.localizedDescription)"
        }
    }
}
