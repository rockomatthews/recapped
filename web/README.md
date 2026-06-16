# Recapped Web

Next.js app for Recapped's public video wall, Google sign-in, profile video walls, and recap uploads.

## Setup

1. Create a Supabase project.
2. Enable Google as an Auth provider.
3. Apply `supabase/migrations/20260608000000_recapped_web_initial.sql`.
4. Copy `.env.example` to `.env.local` and fill:

```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

5. Add the same env vars in Vercel.

## Vercel

This app is in the `web/` subdirectory. In Vercel Project Settings, set:

- Framework Preset: `Next.js`
- Root Directory: `web`
- Build Command: `npm run build`
- Install Command: `npm install`

If the Root Directory is left as the repo root, the production domain can show `404: NOT_FOUND` because Vercel is not deploying the Next app.

## Run

```bash
npm install
npm run dev
npm run build
```

## Desktop Auto-Upload Contract

The macOS app should upload rendered recap videos to:

```text
recapped-videos/<user-id>/<session-id>.mp4
```

Then insert a row into `public.videos` with:

- `user_id`
- `title`
- `storage_path`
- `playback_url`
- `duration_seconds = 60`
- `visibility = public`

The web upload page follows the same flow, so it can be used as the reference implementation for the native app.

## Desktop Pairing

The desktop app uploads through Vercel, not directly to Supabase.

- `/pair` creates a pairing code for the signed-in user.
- `/api/desktop/upload` accepts a paired desktop upload.
- Vercel uses `SUPABASE_SERVICE_ROLE_KEY` server-side to upload the video and insert the `videos` row.

Never put `SUPABASE_SERVICE_ROLE_KEY` in the native app.

## Download Page

The app download route is `/download`. It currently points at GitHub Releases:

```text
https://github.com/rockomatthews/recapped/releases/latest
```

Use `../scripts/package-mac-app.sh` from the repo root to create `dist/Recapped-macOS.zip` for a release asset.
