"use client";

import { LogIn, LogOut } from "lucide-react";
import { getBrowserSupabase } from "@/lib/supabase/client";

export function AuthButton({ userEmail }: { userEmail: string | null }) {
  async function signIn() {
    const supabase = getBrowserSupabase();

    if (!supabase) {
      alert("Supabase env vars are missing.");
      return;
    }

    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });
  }

  async function signOut() {
    const supabase = getBrowserSupabase();
    await supabase?.auth.signOut();
    window.location.href = "/";
  }

  if (userEmail) {
    return (
      <button className="button secondary" onClick={signOut} type="button">
        <LogOut size={16} />
        {userEmail}
      </button>
    );
  }

  return (
    <button className="button" onClick={signIn} type="button">
      <LogIn size={16} />
      Sign in with Google
    </button>
  );
}
