import { useState } from "react";
import { Button } from "./ui/button";
import type { PalsStatus } from "../lib/omart/types";

export function PalsSetup({ status, error, install, refresh }: {
  status: PalsStatus | null;
  error: string | null;
  install: () => Promise<string | null>;
  refresh: () => Promise<void>;
}) {
  const [busy, setBusy] = useState(false);
  const [problem, setProblem] = useState<string | null>(null);
  const phase = status?.phase;
  const source = status?.source ?? "~paldev";
  const labels = {
    missing: "%pals is not installed.",
    installing: `Waiting for %pals to download from ${source}.`,
    waiting: "%pals has a pending desk update. Check +vats %pals in the dojo if it stays here.",
    starting: "The %pals desk is installed. Waiting for the agent to start.",
    suspended: "%pals is suspended. Resume it to use your pals.",
    ready: "%pals is running.",
  };
  const step = phase === "ready" ? 3 : phase === "starting" || phase === "suspended" ? 2
    : phase && phase !== "missing" ? 1 : 0;

  async function start() {
    setBusy(true);
    setProblem(null);
    try {
      setProblem(await install());
    } catch {
      setProblem("Could not reach this ship. Try again.");
    } finally {
      setBusy(false);
    }
  }

  return <section className="max-w-xl rounded-xl bg-surface p-6 shadow-[var(--shadow-border)]">
    <p className="font-mono text-[11px] tracking-wide text-subtle uppercase">%pals · setup</p>
    <h1 className="mt-2 font-display text-3xl tracking-tight italic">Connect with pals</h1>
    <p className="mt-3 text-sm leading-relaxed text-muted">
      Omart uses %pals to exchange listings with other ships. Install it from ~paldev to get started.
    </p>
    <div role="status" aria-live="polite" className="mt-6 text-sm">
      {busy ? "Sending request to your ship…" : phase ? labels[phase] : error ? "Status unavailable." : "Checking %pals…"}
    </div>
    {status && <ol aria-label="Pals install progress" className="mt-4 space-y-2 font-mono text-xs text-muted">
      {["Install requested", "Desk downloaded", "Pals running"].map((label, i) =>
        <li key={label}>{i < step ? "✓" : "○"} {label}</li>)}
    </ol>}
    {(error || problem) && <p role="alert" className="mt-3 text-sm text-danger">{problem ?? error}</p>}
    {(phase === "missing" || phase === "suspended") && <Button className="mt-6" disabled={busy} onClick={start}>
      {phase === "suspended" ? "Resume %pals" : "Install %pals from ~paldev"}
    </Button>}
    {error && <Button variant="secondary" className="mt-4" onClick={() => void refresh()}>Check again</Button>}
    {status && phase !== "missing" && phase !== "ready" && <p className="mt-4 text-xs leading-relaxed text-muted">
      Status updates automatically while this page is visible. For details, run <code>+vats %pals</code> in your ship’s dojo.
    </p>}
  </section>;
}
