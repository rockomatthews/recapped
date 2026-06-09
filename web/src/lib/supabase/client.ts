"use client";

import { createBrowserClient } from "@supabase/ssr";
import { getSupabaseEnv } from "@/lib/env";

let browserClient: ReturnType<typeof createBrowserClient> | null = null;

export function getBrowserSupabase() {
  const env = getSupabaseEnv();

  if (!env) {
    return null;
  }

  if (!browserClient) {
    browserClient = createBrowserClient(env.url, env.publishableKey);
  }

  return browserClient;
}
