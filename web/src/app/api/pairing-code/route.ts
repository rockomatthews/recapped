import { NextResponse } from "next/server";
import { getServerSupabase } from "@/lib/supabase/server";
import { getSupabaseAdmin } from "@/lib/supabase/admin";
import { generatePairingCode, hashPairingCode } from "@/lib/pairing";

export async function POST() {
  const supabase = await getServerSupabase();
  const admin = getSupabaseAdmin();

  if (!supabase || !admin) {
    return NextResponse.json({ error: "Supabase server env vars are not configured." }, { status: 500 });
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Sign in before pairing the desktop app." }, { status: 401 });
  }

  const code = generatePairingCode();
  const codeHash = await hashPairingCode(code);
  const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 365).toISOString();

  const { error } = await (admin as any).from("desktop_pairing_codes").insert({
    user_id: user.id,
    code_hash: codeHash,
    expires_at: expiresAt,
  });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ code, expiresAt });
}
