# Recapped Architecture

Recapped is split into four modules:

- `RecappedApp`: SwiftUI shell, recording controls, recap progress, and preview.
- `RecappedCore`: session state, automatic capture rules, timeline metadata, and recap job models.
- `RecappedCapture`: macOS screenshot capture and local session storage.
- `RecappedAI`: AI recap provider interfaces, frame selection, captions, and video rendering.

## Capture Model

V1 records only after the user starts a session. While active, the app evaluates activity samples and captures automatically when:

- the foreground app changes,
- the fallback interval expires,
- a manual capture is requested by the app.

The default implementation writes PNG screenshots and JSON metadata into an Application Support session folder.

## AI Recap Model

When the user stops a session, the app creates an AI recap job from the captured image sequence. The initial provider boundary accepts a full captured session and returns a video path plus a summary. The local provider selects meaningful frames, generates chapter captions from metadata, and renders a 60-second slideshow-style video. A hosted image-to-video provider can replace this without changing the app/session layer.

## Privacy Defaults

Captured frames stay local by default. The initial app has explicit start/stop controls and never records outside an active session. App/window exclusions and redaction belong in the capture rules before any hosted AI provider is enabled.
