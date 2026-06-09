import Link from "next/link";
import type { RecapVideo } from "@/lib/types";

const dateFormatter = new Intl.DateTimeFormat("en", {
  month: "short",
  day: "numeric",
});

export function VideoCard({ video }: { video: RecapVideo }) {
  const creator = video.profiles?.display_name ?? "Recapped user";
  const avatar = video.profiles?.avatar_url;

  return (
    <article className="video-card">
      <div className="video-frame">
        <video
          src={video.playback_url}
          poster={video.thumbnail_url ?? undefined}
          preload="metadata"
          controls
          muted
        />
        <span className="duration">{formatDuration(video.duration_seconds)}</span>
      </div>
      <div className="video-meta">
        <h2>{video.title}</h2>
        <Link className="byline" href={`/profile/${video.user_id}`}>
          <span className="avatar">
            {avatar ? <img alt="" src={avatar} /> : null}
          </span>
          <span>
            {creator} · {dateFormatter.format(new Date(video.created_at))}
          </span>
        </Link>
      </div>
    </article>
  );
}

function formatDuration(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = Math.round(seconds % 60);
  return `${minutes}:${remainingSeconds.toString().padStart(2, "0")}`;
}
