"use client";

import { useState } from "react";
import { KeyRound } from "lucide-react";

export function PairingCodePanel() {
  const [code, setCode] = useState<string | null>(null);
  const [status, setStatus] = useState("Create a code, paste it into the Mac app once, then uploads are hands-off.");
  const [isLoading, setIsLoading] = useState(false);

  async function createCode() {
    setIsLoading(true);
    setStatus("Creating pairing code...");

    const response = await fetch("/api/pairing-code", {
      method: "POST",
    });
    const payload = await response.json();

    if (!response.ok) {
      setStatus(payload.error ?? "Could not create pairing code.");
      setIsLoading(false);
      return;
    }

    setCode(payload.code);
    setStatus("Paste this code into Recapped on your Mac.");
    setIsLoading(false);
  }

  return (
    <div className="panel pairing-panel">
      <KeyRound size={22} />
      <h2>Pair the desktop app</h2>
      <p>{status}</p>
      {code ? <div className="pairing-code">{code}</div> : null}
      <button className="button" type="button" onClick={createCode} disabled={isLoading}>
        {isLoading ? "Creating..." : "Create pairing code"}
      </button>
    </div>
  );
}
