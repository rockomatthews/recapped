# Recapped

Recapped is a native macOS app that automatically captures screenshots during a work session and turns the resulting image history into a one-minute recap video.

## V1 Goal

- Start a recording session manually.
- Capture screenshots automatically while the session is active.
- Trigger captures from visible activity signals such as foreground app changes.
- Keep a fallback interval so long-running work is still represented.
- Store captured images and metadata locally by session.
- Run an AI recap pipeline when the session stops.
- Produce a 60-second recap video from the captured screenshots.

## Build

```bash
swift build
swift test
swift run Recapped
```

The app uses a package-first SwiftPM layout so the core logic can be tested without opening Xcode.
