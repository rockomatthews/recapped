import { NextResponse, type NextRequest } from "next/server";
import { getSupabaseEnv } from "@/lib/env";

export async function GET(request: NextRequest) {
  const env = getSupabaseEnv();

  if (!env) {
    return NextResponse.json(
      {
        enabled: false,
        message: "Supabase environment variables are not configured in this deployment.",
      },
      { status: 500 }
    );
  }

  const provider = request.nextUrl.searchParams.get("provider") ?? "google";
  const redirectTo = new URL("/auth/callback", request.nextUrl.origin);
  const authorizeURL = new URL("/auth/v1/authorize", env.url);
  authorizeURL.searchParams.set("provider", provider);
  authorizeURL.searchParams.set("redirect_to", redirectTo.toString());

  try {
    const response = await fetch(authorizeURL, {
      headers: { accept: "application/json" },
      redirect: "manual",
    });

    if (response.status >= 300 && response.status < 400) {
      return NextResponse.json({ enabled: true });
    }

    const contentType = response.headers.get("content-type") ?? "";
    const payload = contentType.includes("application/json")
      ? await response.json().catch(() => null)
      : null;
    const message = typeof payload?.msg === "string" ? payload.msg : null;
    const isProviderDisabled =
      response.status === 400 &&
      typeof message === "string" &&
      message.toLowerCase().includes("provider is not enabled");

    if (isProviderDisabled) {
      return NextResponse.json({
        enabled: false,
        message: "Google sign-in is not enabled in this Supabase project yet.",
      });
    }

    return NextResponse.json(
      {
        enabled: false,
        message: message ?? "Supabase rejected the Google sign-in request.",
      },
      { status: response.status || 500 }
    );
  } catch {
    return NextResponse.json(
      {
        enabled: false,
        message: "Could not reach Supabase Auth from this deployment.",
      },
      { status: 502 }
    );
  }
}
