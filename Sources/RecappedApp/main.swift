import AppKit
import SwiftUI
import RecappedAI
import RecappedCapture
import RecappedCore
import RecappedUpload

@main
enum RecappedMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = RecappedAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
        _ = delegate
    }
}

final class RecappedAppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView()
            .frame(minWidth: 720, minHeight: 520)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 560),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Recapped"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
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
                } else if model.isProcessing {
                    Button("Working...") {}
                        .disabled(true)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button(model.primaryActionTitle) {
                        Task { await model.start() }
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.canStartRecording)
                }
            }

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                GridRow {
                    metric("Frames", value: "\(model.frameCount)")
                    metric("Backend", value: model.backendName)
                    metric("Permission", value: model.permissionState)
                    metric("Recap", value: model.recapState)
                    metric("Upload", value: model.uploadState)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Website upload")
                    .font(.headline)
                TextField("Web URL", text: $model.webURLString)
                    .textFieldStyle(.roundedBorder)
                SecureField("Pairing code from /pair", text: $model.pairingCode)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    if model.canRetryLatestUpload {
                        Button("Retry latest upload") {
                            Task { await model.uploadLatest() }
                        }
                    }

                    Text(model.uploadHelpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    @Published private(set) var isProcessing = false
    @Published private(set) var recapState = "Idle"
    @Published private(set) var uploadState = "Not configured"
    @Published private(set) var permissionState = ScreenRecordingPermission.isGranted() ? "Granted" : "Needed"
    @Published private(set) var statusText = "Pair Recapped before recording so Stop can upload automatically."
    @Published private(set) var lastResult: RecapResult?
    @Published var webURLString = SessionViewModel.initialWebURL {
        didSet {
            UserDefaults.standard.set(webURLString, forKey: Self.webURLDefaultsKey)
            refreshUploadReadiness()
        }
    }
    @Published var pairingCode = SessionViewModel.initialPairingCode {
        didSet {
            UserDefaults.standard.set(pairingCode, forKey: Self.pairingCodeDefaultsKey)
            refreshUploadReadiness()
        }
    }

    let backendName = CaptureBackend.defaultBackend.rawValue

    private static let webURLDefaultsKey = "recapped.webURL"
    private static let pairingCodeDefaultsKey = "recapped.pairingCode"
    private static let initialWebURL = ProcessInfo.processInfo.environment["RECAPPED_WEB_URL"]
        ?? UserDefaults.standard.string(forKey: webURLDefaultsKey)
        ?? "https://recapped-three.vercel.app"
    private static let initialPairingCode = ProcessInfo.processInfo.environment["RECAPPED_PAIRING_CODE"]
        ?? UserDefaults.standard.string(forKey: pairingCodeDefaultsKey)
        ?? ""

    private var state = CaptureSessionState()
    private var decider = AutomaticCaptureDecider()
    private var timer: Timer?
    private let capturer = CoreGraphicsScreenshotCapturer()
    private let activitySampler = MacActivitySampler()
    private let recapOrchestrator = RecapOrchestrator(provider: LocalAIRecapProvider())
    private var store: SessionImageStore?
    private var lastCapturedSession: CapturedSession?

    init() {
        refreshUploadReadiness()
        if uploadConfig() != nil {
            statusText = "Ready. Stop will render and upload automatically."
        }
    }

    var canStartRecording: Bool {
        uploadConfig() != nil && !isProcessing
    }

    var primaryActionTitle: String {
        uploadConfig() == nil ? "Pair before Start" : "Start"
    }

    var canRetryLatestUpload: Bool {
        lastResult != nil && uploadConfig() != nil && uploadState != "Uploading" && uploadState != "Uploaded"
    }

    var uploadHelpText: String {
        if uploadConfig() == nil {
            return "Paste a Pair App code before recording. Then Stop renders and uploads automatically."
        }

        if uploadState == "Uploaded" {
            return "Automatic upload complete."
        }

        return "Paired. Stop will render and upload automatically."
    }

    func start() async {
        guard !isRecording else { return }
        guard uploadConfig() != nil else {
            uploadState = "Not paired"
            statusText = "Paste a Pair App code before recording. Automatic upload starts after Stop."
            return
        }

        do {
            if !ScreenRecordingPermission.isGranted() {
                permissionState = "Requesting"
                if !ScreenRecordingPermission.request() {
                    permissionState = "Needed"
                    statusText = "Screen recording permission is required before Recapped can capture."
                    return
                }
            }

            permissionState = "Granted"
            store = try SessionImageStore.defaultStore()
            state = CaptureSessionState()
            state.start(at: Date())
            decider.reset()
            frameCount = 0
            lastResult = nil
            lastCapturedSession = nil
            recapState = "Recording"
            uploadState = "Will upload"
            statusText = "Recording automatically. Stop will render and upload to Recapped."
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
        isProcessing = true
        defer { isProcessing = false }
        recapState = "Rendering"
        uploadState = "Waiting"
        statusText = "Rendering a 60-second AI recap from \(state.frames.count) frame(s). Upload starts next."

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
            let result = try await recapOrchestrator.renderOneMinuteRecap(
                for: capturedSession,
                outputURL: outputURL
            )
            lastResult = result
            lastCapturedSession = capturedSession
            recapState = "Rendered"
            statusText = "Recap rendered. Uploading automatically now."
        } catch {
            recapState = "Failed"
            statusText = "Recap failed: \(error.localizedDescription)"
            return
        }

        do {
            if let lastResult, let lastCapturedSession {
                try await uploadIfConfigured(result: lastResult, session: lastCapturedSession)
            }
        } catch {
            recapState = "Rendered"
            uploadState = "Failed"
            statusText = "Recap rendered locally, but upload failed: \(error.localizedDescription)"
        }
    }

    func uploadLatest() async {
        guard let lastResult, let lastCapturedSession else {
            statusText = "No rendered recap is ready to upload yet."
            return
        }

        do {
            try await uploadIfConfigured(result: lastResult, session: lastCapturedSession)
        } catch {
            recapState = "Rendered"
            uploadState = "Failed"
            statusText = "Recap rendered locally, but upload failed: \(error.localizedDescription)"
        }
    }

    private func uploadIfConfigured(result: RecapResult, session: CapturedSession) async throws {
        guard let uploadConfig = uploadConfig() else {
            uploadState = "Not paired"
            throw UploadFlowError.notPaired
        }

        uploadState = "Uploading"
        statusText = "Uploading recap to Recapped."

        let uploaded = try await SiteVideoUploader(config: uploadConfig).upload(
            videoURL: result.videoURL,
            title: "Recapped session \(session.startedAt.formatted(date: .abbreviated, time: .shortened))",
            description: result.summary,
            durationSeconds: Int(result.durationSeconds.rounded())
        )

        uploadState = "Uploaded"
        recapState = "Done"
        statusText = "Recap complete and uploaded: \(uploaded.playbackURL.absoluteString)"
    }

    private func uploadConfig() -> SiteUploadConfig? {
        guard
            let webBaseURL = URL(string: webURLString),
            !pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return SiteUploadConfig(webBaseURL: webBaseURL, pairingCode: pairingCode)
    }

    private func refreshUploadReadiness() {
        guard !isRecording, uploadState != "Uploading", uploadState != "Uploaded" else { return }
        uploadState = uploadConfig() == nil ? "Not paired" : "Ready"

        if uploadConfig() != nil, lastResult == nil, recapState == "Idle" {
            statusText = "Ready. Stop will render and upload automatically."
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

        let sample = activitySampler.sample()
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

private enum UploadFlowError: LocalizedError {
    case notPaired

    var errorDescription: String? {
        "Recapped is not paired. Paste a Pair App code before recording so Stop can upload automatically."
    }
}
