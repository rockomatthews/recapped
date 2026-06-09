import { AppShell } from "@/components/app-shell";
import { UploadForm } from "@/components/upload-form";
import { getCurrentUser } from "@/lib/videos";

export default async function UploadPage() {
  const user = await getCurrentUser();

  return (
    <AppShell>
      <main className="upload-page">
        <section className="panel upload-panel">
          <h1>Upload a recap video</h1>
          <p>
            This is the same storage path the desktop app will use automatically after
            rendering a one-minute session recap.
          </p>
          {user ? (
            <UploadForm />
          ) : (
            <div className="notice">
              Sign in with Google first. After auth is connected, uploads go to the
              `recapped-videos` Supabase Storage bucket and publish into the video wall.
            </div>
          )}
        </section>

        <aside className="panel upload-panel">
          <h2>Desktop auto-upload contract</h2>
          <p>
            The native app should upload to `recapped-videos/&lt;user-id&gt;/&lt;session-id&gt;.mp4`
            with the user session, then insert a row into `videos`.
          </p>
        </aside>
      </main>
    </AppShell>
  );
}
