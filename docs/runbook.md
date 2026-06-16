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

If Terminal says `Build of product 'Recapped' complete!` but no window appears, stop the process with `Control-C`, pull the latest code, and run the script again. The current app uses an explicit AppKit foreground window launcher.

## Current Upload State

The website has Google sign-in, Supabase Storage upload, the global wall, profile walls, a Download page, and a Pair App page. The native macOS app captures, filters, renders, and uploads after `Stop` when paired with the website.

Pairing flow:

1. Sign in on the site.
2. Open `/pair`.
3. Create a pairing code.
4. Paste the website URL and pairing code into Recapped for macOS.

Do not use a service role key or Supabase key in the native app. Vercel handles Supabase uploads server-side.
