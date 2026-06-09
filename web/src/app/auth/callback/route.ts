import { NextResponse, type NextRequest } from "next/server";
import { getServerSupabase } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const requestURL = new URL(request.url);
  const code = requestURL.searchParams.get("code");
  const next = requestURL.searchParams.get("next") ?? "/";

  if (code) {
    const supabase = await getServerSupabase();
    await supabase?.auth.exchangeCodeForSession(code);
  }

  return NextResponse.redirect(new URL(next, requestURL.origin));
}
