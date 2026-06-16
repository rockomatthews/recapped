import Link from "next/link";
import { Clapperboard, Upload } from "lucide-react";
import { getCurrentUser } from "@/lib/videos";
import { AuthButton } from "@/components/auth-button";

export async function AppShell({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  return (
    <div className="app-shell">
      <header className="topbar">
        <Link className="brand" href="/">
          <span className="brand-mark">
            <Clapperboard size={18} strokeWidth={2.4} />
          </span>
          Recapped
        </Link>

        <nav className="nav" aria-label="Primary">
          <Link href="/">Global Wall</Link>
          {user ? <Link href={`/profile/${user.id}`}>My Profile</Link> : null}
          <Link href="/upload">Upload</Link>
          <Link href="/download">Download</Link>
          <Link href="/pair">Pair App</Link>
        </nav>

        <div className="topbar-spacer" />

        {user ? (
          <Link className="button secondary" href="/upload">
            <Upload size={16} />
            Upload recap
          </Link>
        ) : null}
        <AuthButton userEmail={user?.email ?? null} />
      </header>
      {children}
    </div>
  );
}
