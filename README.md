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

On first run, macOS must grant screen recording permission before Recapped can capture screenshots.

## Start Capturing

```bash
./scripts/run-recapped.sh
```

Click `Start` in the app window, approve Screen Recording permission, then click `Stop` when you want Recapped to render the 60-second montage. Local session output is written under:

```text
~/Library/Application Support/Recapped/Sessions/<session-id>/
```

To rerender the latest saved session after changing the selection algorithm:

```bash
./scripts/rerender-latest.sh
```

Or pass a specific session folder:

```bash
./scripts/rerender-latest.sh "$HOME/Library/Application Support/Recapped/Sessions/<session-id>"
```

The web app lives in `web/`. On Vercel, set the project Root Directory to `web`; otherwise Vercel can deploy the wrong folder and show `404: NOT_FOUND`.

## Hands-Off Upload

Clicking `Stop` renders the recap and automatically uploads it when the app is paired with the website:

1. Sign in on the website.
2. Open `/pair`.
3. Create a pairing code.
4. Paste the website URL and pairing code into the Mac app.

No Supabase key belongs in the native app. Vercel handles Supabase uploads server-side.

## Package the macOS App

```bash
./scripts/package-mac-app.sh
```

This writes:

```text
dist/Recapped-macOS.zip
```
