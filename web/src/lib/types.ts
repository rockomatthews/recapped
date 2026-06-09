export type Profile = {
  id: string;
  display_name: string | null;
  avatar_url: string | null;
  created_at: string;
};

export type RecapVideo = {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  storage_path: string;
  playback_url: string;
  thumbnail_url: string | null;
  duration_seconds: number;
  visibility: "public" | "private";
  created_at: string;
  profiles?: Profile | null;
};
