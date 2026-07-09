"use client";

import { useState } from "react";
import { LogIn, LogOut } from "lucide-react";
import { getBrowserSupabase } from "@/lib/supabase/client";

export function AuthButton({ userEmail }: { userEmail: string | null }) {
  const [status, setStatus] = useState<string | null>(null);
  const [isSigningIn, setIsSigningIn] = useState(false);

  async function signIn() {
    setIsSigningIn(true);
    setStatus(null);

    const supabase = getBrowserSupabase();

    if (!supabase) {
      setStatus("Supabase env vars are missing.");
      setIsSigningIn(false);
      return;
    }

    const providerResponse = await fetch("/api/auth/provider-status?provider=google");
    const providerStatus = await providerResponse.json().catch(() => null);

    if (!providerResponse.ok || !providerStatus?.enabled) {
      setStatus(providerStatus?.message ?? "Google sign-in is not ready yet.");
      setIsSigningIn(false);
      return;
    }

    const { error } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) {
      setStatus(error.message);
      setIsSigningIn(false);
    }
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
    <div className="auth-control">
      <button className="button" disabled={isSigningIn} onClick={signIn} type="button">
        <LogIn size={16} />
        {isSigningIn ? "Checking sign-in..." : "Sign in with Google"}
      </button>
      {status ? <span className="auth-error">{status}</span> : null}
    </div>
  );
}
