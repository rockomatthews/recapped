import { getServerSupabase } from "@/lib/supabase/server";
import type { RecapVideo } from "@/lib/types";

export async function getGlobalVideos(): Promise<RecapVideo[]> {
  const supabase = await getServerSupabase();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from("videos")
    .select("*, profiles:user_id(id, display_name, avatar_url, created_at)")
    .eq("visibility", "public")
    .order("created_at", { ascending: false })
    .limit(60);

  if (error) {
    console.error("Failed to load global videos", error.message);
    return [];
  }

  return (data ?? []) as RecapVideo[];
}

export async function getProfileVideos(profileID: string): Promise<RecapVideo[]> {
  const supabase = await getServerSupabase();

  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from("videos")
    .select("*, profiles:user_id(id, display_name, avatar_url, created_at)")
    .eq("user_id", profileID)
    .eq("visibility", "public")
    .order("created_at", { ascending: false });

  if (error) {
    console.error("Failed to load profile videos", error.message);
    return [];
  }

  return (data ?? []) as RecapVideo[];
}

export async function getCurrentUser() {
  const supabase = await getServerSupabase();

  if (!supabase) {
    return null;
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();

  return user;
}
