import type { RecapVideo } from "@/lib/types";
import { VideoCard } from "@/components/video-card";

export function VideoWall({ videos }: { videos: RecapVideo[] }) {
  if (videos.length === 0) {
    return (
      <div className="empty-state">
        <div>
          <h2>No recap videos yet</h2>
          <p>Once Recapped starts uploading one-minute work summaries, they will land here.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="video-grid">
      {videos.map((video) => (
        <VideoCard key={video.id} video={video} />
      ))}
    </div>
  );
}
