import { AppShell } from "@/components/app-shell";
import { VideoWall } from "@/components/video-wall";
import { getProfileVideos } from "@/lib/videos";

type ProfilePageProps = {
  params: Promise<{ id: string }>;
};

export default async function ProfilePage({ params }: ProfilePageProps) {
  const { id } = await params;
  const videos = await getProfileVideos(id);
  const profile = videos[0]?.profiles;

  return (
    <AppShell>
      <main className="profile-page">
        <header className="profile-head">
          <div className="profile-avatar">
            {profile?.avatar_url ? <img alt="" src={profile.avatar_url} /> : null}
          </div>
          <div>
            <h1>{profile?.display_name ?? "Recapped profile"}</h1>
            <p>{videos.length} public automatic recap video{videos.length === 1 ? "" : "s"}.</p>
          </div>
        </header>

        <VideoWall videos={videos} />
      </main>
    </AppShell>
  );
}
