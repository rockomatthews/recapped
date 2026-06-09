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
