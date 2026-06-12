# Recapped Runbook

## Fix a Vercel `404: NOT_FOUND`

The Next.js site lives in `web/`. In Vercel, set:

- Framework Preset: `Next.js`
- Root Directory: `web`
- Build Command: `npm run build`
- Install Command: `npm install`

Then redeploy. If Vercel points at the repo root, it will not find the Next app and can serve `404: NOT_FOUND` at the production domain.

## Start the macOS Screenshot App

From the repo root:

```bash
./scripts/run-recapped.sh
```

Or directly:

```bash
swift run Recapped
```

In the app window:

1. Click `Start`.
2. Approve macOS Screen Recording permission if prompted.
3. Do some work.
4. Click `Stop`.
5. Recapped renders `recap.mp4` in the session folder under:

```text
~/Library/Application Support/Recapped/Sessions/<session-id>/
```

If macOS does not show a permission prompt, open System Settings → Privacy & Security → Screen & System Audio Recording, enable the terminal/Codex app used to launch Recapped, then quit and restart the app.

## Current Upload State

The website has Google sign-in, Supabase Storage upload, the global wall, and profile walls. The native macOS app currently captures and renders the recap video locally. Native automatic upload to Supabase is the next integration step.
