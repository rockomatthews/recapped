import { AppShell } from "@/components/app-shell";
import { PairingCodePanel } from "@/components/pairing-code-panel";
import { getCurrentUser } from "@/lib/videos";

export default async function PairPage() {
  const user = await getCurrentUser();

  return (
    <AppShell>
      <main className="download-page">
        <section className="download-hero">
          <div>
            <h1>Pair Recapped with this account</h1>
            <p>
              Generate a desktop pairing code. The Mac app uses it to upload rendered
              recaps through this site without putting Supabase keys on your machine.
            </p>
          </div>
        </section>

        {user ? (
          <PairingCodePanel />
        ) : (
          <div className="notice">Sign in with Google before creating a desktop pairing code.</div>
        )}
      </main>
    </AppShell>
  );
}
