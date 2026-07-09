import { AppShell } from "@/components/app-shell";
import { UploadForm } from "@/components/upload-form";
import { getCurrentUser } from "@/lib/videos";
import Link from "next/link";

export default async function UploadPage() {
  const user = await getCurrentUser();

  return (
    <AppShell>
      <main className="upload-page">
        <section className="panel upload-panel">
          <h1>Manual recap upload</h1>
          <p>
            This page is only the fallback for uploading an existing MP4 by hand. The
            normal Recapped flow is to pair the Mac app once, then let it upload
            automatically after Stop renders the one-minute recap.
          </p>
          {user ? (
            <UploadForm />
          ) : (
            <div className="notice upload-notice">
              <strong>Sign in with Google to use manual upload.</strong>
              <span>
                If you want the hands-off desktop flow, sign in, open Pair App, create
                a pairing code, and paste it into Recapped on your Mac.
              </span>
              <div className="inline-actions">
                <Link className="button secondary" href="/pair">
                  Pair App
                </Link>
                <Link className="button secondary" href="/download">
                  Download app
                </Link>
              </div>
            </div>
          )}
        </section>

        <aside className="panel upload-panel">
          <h2>Desktop auto-upload path</h2>
          <p>
            Recapped renders locally on Stop, sends the MP4 to this site with your
            pairing code, and the server writes it into Supabase Storage plus the
            video wall. No Supabase keys belong in the Mac app.
          </p>
        </aside>
      </main>
    </AppShell>
  );
}
