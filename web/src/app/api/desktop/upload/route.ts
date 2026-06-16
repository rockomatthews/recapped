import { NextResponse, type NextRequest } from "next/server";
import { hashPairingCode } from "@/lib/pairing";
import { getSupabaseAdmin } from "@/lib/supabase/admin";

export async function POST(request: NextRequest) {
  const admin = getSupabaseAdmin();

  if (!admin) {
    return NextResponse.json({ error: "Supabase server env vars are not configured." }, { status: 500 });
  }

  const formData = await request.formData();
  const code = String(formData.get("code") ?? "");
  const title = String(formData.get("title") ?? "Recapped session").slice(0, 140);
  const descriptionValue = String(formData.get("description") ?? "");
  const file = formData.get("video");

  if (!code || !(file instanceof File)) {
    return NextResponse.json({ error: "Pairing code and video file are required." }, { status: 400 });
  }

  const codeHash = await hashPairingCode(code);
  const { data: pairing, error: pairingError } = await (admin as any)
    .from("desktop_pairing_codes")
    .select("user_id")
    .eq("code_hash", codeHash)
    .is("revoked_at", null)
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();

  if (pairingError) {
    return NextResponse.json({ error: pairingError.message }, { status: 500 });
  }

  if (!pairing) {
    return NextResponse.json({ error: "Invalid or expired pairing code." }, { status: 401 });
  }

  const objectID = crypto.randomUUID();
  const storagePath = `${pairing.user_id}/${objectID}.mp4`;
  const bytes = Buffer.from(await file.arrayBuffer());

  const { error: uploadError } = await admin.storage
    .from("recapped-videos")
    .upload(storagePath, bytes, {
      contentType: file.type || "video/mp4",
      cacheControl: "3600",
      upsert: false,
    });

  if (uploadError) {
    return NextResponse.json({ error: uploadError.message }, { status: 500 });
  }

  const { data: publicURL } = admin.storage.from("recapped-videos").getPublicUrl(storagePath);

  const { error: insertError } = await (admin as any).from("videos").insert({
    user_id: pairing.user_id,
    title,
    description: descriptionValue || null,
    storage_path: storagePath,
    playback_url: publicURL.publicUrl,
    duration_seconds: 60,
    visibility: "public",
  });

  if (insertError) {
    return NextResponse.json({ error: insertError.message }, { status: 500 });
  }

  return NextResponse.json({
    storagePath,
    playbackURL: publicURL.publicUrl,
  });
}
