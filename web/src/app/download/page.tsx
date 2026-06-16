import { AppShell } from "@/components/app-shell";
import { Download, ShieldCheck, Sparkles } from "lucide-react";

export default function DownloadPage() {
  return (
    <AppShell>
      <main className="download-page">
        <section className="download-hero">
          <div>
            <h1>Download Recapped for macOS</h1>
            <p>
              Capture your work automatically, reject sensitive screenshots, render a
              one-minute montage on Stop, and upload it when connected.
            </p>
            <a className="button" href="https://github.com/rockomatthews/recapped/releases/latest">
              <Download size={16} />
              Download latest build
            </a>
          </div>
        </section>

        <section className="download-grid">
          <div className="panel download-card">
            <Sparkles size={22} />
            <h2>Whole-session montage</h2>
            <p>Frames are scored across the entire session for quality, variety, and timeline coverage.</p>
          </div>
          <div className="panel download-card">
            <ShieldCheck size={22} />
            <h2>Secret-aware filtering</h2>
            <p>Local OCR checks for private keys, service role keys, API secrets, and common token patterns.</p>
          </div>
          <div className="panel download-card">
            <Download size={22} />
            <h2>Automatic upload</h2>
            <p>After Stop, Recapped renders and uploads automatically once paired with your website account.</p>
          </div>
        </section>
      </main>
    </AppShell>
  );
}
