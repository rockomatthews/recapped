import { AppShell } from "@/components/app-shell";
import { VideoWall } from "@/components/video-wall";
import { getGlobalVideos } from "@/lib/videos";

export default async function HomePage() {
  const videos = await getGlobalVideos();

  return (
    <AppShell>
      <main className="page">
        <aside className="rail">
          <section className="panel rail-section">
            <h2>Search</h2>
            <input className="search" placeholder="Find recaps" aria-label="Search recaps" />
          </section>

          <section className="panel rail-section">
            <h3>Filters</h3>
            <div className="filter-list">
              <div className="filter-chip">
                <strong>All work</strong>
                <span>{videos.length}</span>
              </div>
              <div className="filter-chip">
                <strong>Today</strong>
                <span>Auto</span>
              </div>
              <div className="filter-chip">
                <strong>One minute</strong>
                <span>1:00</span>
              </div>
            </div>
          </section>
        </aside>

        <section className="main-column">
          <div className="section-header">
            <div>
              <h1>Watch what people actually accomplished.</h1>
              <p>
                A live wall of one-minute desktop recap videos generated from automatic
                Recapped sessions.
              </p>
            </div>
          </div>
          <VideoWall videos={videos} />
        </section>

        <aside className="rail">
          <section className="panel status-panel">
            <h2>Upload status</h2>
            <p className="status-line">
              <span className="dot" />
              Desktop uploads will appear here as soon as Supabase receives the recap video.
            </p>
          </section>
          <section className="panel status-panel">
            <h2>Automatic path</h2>
            <p className="status-line">
              Recapped app → Supabase Storage → videos table → global wall and profile wall.
            </p>
          </section>
        </aside>
      </main>
    </AppShell>
  );
}
