"use client";

import { useState } from "react";
import { UploadCloud } from "lucide-react";
import { getBrowserSupabase } from "@/lib/supabase/client";

export function UploadForm() {
  const [status, setStatus] = useState<string>("Ready");
  const [isUploading, setIsUploading] = useState(false);

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsUploading(true);
    setStatus("Preparing upload...");

    const supabase = getBrowserSupabase();
    if (!supabase) {
      setStatus("Missing Supabase environment variables.");
      setIsUploading(false);
      return;
    }

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      setStatus("Sign in with Google before uploading.");
      setIsUploading(false);
      return;
    }

    const form = new FormData(event.currentTarget);
    const file = form.get("video") as File | null;
    const title = String(form.get("title") ?? "").trim();
    const description = String(form.get("description") ?? "").trim();
    const visibility = String(form.get("visibility") ?? "public");

    if (!file || file.size === 0 || !title) {
      setStatus("Choose a video and add a title.");
      setIsUploading(false);
      return;
    }

    const safeName = file.name.replace(/[^a-z0-9._-]/gi, "-").toLowerCase();
    const path = `${user.id}/${crypto.randomUUID()}-${safeName}`;

    setStatus("Uploading video...");
    const { error: uploadError } = await supabase.storage
      .from("recapped-videos")
      .upload(path, file, {
        cacheControl: "3600",
        upsert: false,
        contentType: file.type || "video/mp4",
      });

    if (uploadError) {
      setStatus(uploadError.message);
      setIsUploading(false);
      return;
    }

    const { data: publicURL } = supabase.storage.from("recapped-videos").getPublicUrl(path);

    setStatus("Publishing to the wall...");
    const { error: insertError } = await supabase.from("videos").insert({
      user_id: user.id,
      title,
      description: description || null,
      storage_path: path,
      playback_url: publicURL.publicUrl,
      duration_seconds: 60,
      visibility,
    });

    if (insertError) {
      setStatus(insertError.message);
      setIsUploading(false);
      return;
    }

    setStatus("Uploaded. Your recap is on the wall.");
    setIsUploading(false);
    event.currentTarget.reset();
  }

  return (
    <form className="form" onSubmit={onSubmit}>
      <div className="field">
        <label htmlFor="title">Title</label>
        <input id="title" name="title" placeholder="Built the onboarding prototype" required />
      </div>

      <div className="field">
        <label htmlFor="description">Description</label>
        <textarea
          id="description"
          name="description"
          placeholder="A quick note about what this recap shows."
        />
      </div>

      <div className="field">
        <label htmlFor="visibility">Visibility</label>
        <select id="visibility" name="visibility" defaultValue="public">
          <option value="public">Public wall</option>
          <option value="private">Private</option>
        </select>
      </div>

      <div className="field">
        <label htmlFor="video">Recap video</label>
        <input id="video" name="video" type="file" accept="video/*" required />
      </div>

      <button className="button" disabled={isUploading} type="submit">
        <UploadCloud size={16} />
        {isUploading ? "Uploading..." : "Upload recap"}
      </button>

      <p className={status.includes("Missing") || status.includes("Sign in") ? "error" : ""}>
        {status}
      </p>
    </form>
  );
}
