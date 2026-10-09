import { createFileRoute } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { Sigil } from "@/components/sigil";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { PalsSetup } from "@/components/pals-setup";
import { DISPLAY_NAMES } from "@/lib/omart/ships";
import { useOmart } from "@/lib/omart/store";
import type { HearMode } from "@/lib/omart/types";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/pals")({ component: PalsPage });

function PalsPage() {
  const log = useOmart((s) => s.log);
  const config = useOmart((s) => s.config);
  const setConfig = useOmart((s) => s.setConfig);
  const our = useOmart((s) => s.our);
  const pals = useOmart((s) => s.pals);
  const palsStatus = useOmart((s) => s.palsStatus);
  const palsError = useOmart((s) => s.palsError);
  const installPals = useOmart((s) => s.installPals);
  const refresh = useOmart((s) => s.refresh);
  const retryConnections = useOmart((s) => s.retryConnections);
  const plugins = useOmart((s) => s.plugins);
  const meet = useOmart((s) => s.meet);
  const part = useOmart((s) => s.part);
  const connected = pals.filter((pal) => pal.connection === "connected").length;
  const [who, setWho] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [retrying, setRetrying] = useState(false);
  const [retryNote, setRetryNote] = useState<string | null>(null);

  async function retry() {
    setRetrying(true);
    setRetryNote(null);
    try {
      const problem = await retryConnections();
      setError(problem);
      if (!problem) setRetryNote("Sync requested. Listings and withdrawals update automatically.");
    } finally {
      setRetrying(false);
    }
  }

  async function addPal(ship: string) {
    try {
      const problem = await meet(ship);
      setError(problem);
      if (!problem) setWho("");
    } catch {
      setError("Could not reach this ship. Try again.");
    }
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    const ship = who.trim().startsWith("~") ? who.trim() : `~${who.trim()}`;
    if (ship.length > 3) await addPal(ship);
  }

  if (palsStatus?.phase !== "ready") {
    return <PalsSetup status={palsStatus} error={palsError} install={installPals} refresh={refresh} />;
  }

  return (
    <div className="grid gap-10 lg:grid-cols-[minmax(0,1fr)_20rem]">
      <div className="contents lg:flex lg:flex-col lg:gap-10">
        <div className="order-1 lg:order-none">
          <p className="font-mono text-[11px] tracking-wide text-subtle uppercase">%pals · gossip</p>
          <h1 className="mt-2 font-display text-4xl tracking-tight italic">Who you hear</h1>
          <p className="mt-3 max-w-xl text-sm leading-relaxed text-muted">
            Add each other as pals to exchange listings with the default settings. Hops controls
            how far the listings you publish can travel through your pals.
          </p>

          <p className="mt-3 max-w-xl text-xs leading-relaxed text-muted">
            Signed sharing requires the updated Omart on both ships. Pals share cached signed
            listings within the publisher’s hop limit. Withdrawals continue through the network
            so peers can remove older copies. Catalogs catch up every five minutes and on connection.
          </p>
        </div>

        <section className="order-3 lg:order-none">
          <h2 className="font-display text-2xl italic">Pals</h2>
          <p className="mt-1 text-sm text-muted">
            {pals.length} on this ship · {connected} connected
          </p>
          <Button type="button" variant="secondary" className="mt-4" disabled={retrying} onClick={retry}>
            {retrying ? "Syncing…" : "Sync listings"}
          </Button>
          <p className="mt-2 text-xs text-muted">Reconnect to eligible pals and catch up on signed listings and withdrawals, including existing connections.</p>
          {retryNote && <p role="status" className="mt-2 text-xs text-muted">{retryNote}</p>}

          <form onSubmit={submit} className="mt-5 flex flex-col gap-2 sm:flex-row">
            <Input
              value={who}
              onChange={(e) => setWho(e.target.value)}
              placeholder="~sampel-palnet"
              aria-label="Ship to meet"
              className="font-mono"
            />
            <Button type="submit" className="sm:w-32">
              Meet
            </Button>
          </form>
          {error && <p role="alert" className="mt-2 text-sm text-muted">{error}</p>}

          {pals.length === 0 ? (
            <p className="mt-6 text-sm text-muted">No pals yet. Meet a ship to open the first ring.</p>
          ) : (
            <ul className="mt-5 space-y-2">
              {pals.map((pal) => (
                <li
                  key={pal.ship}
                  className="flex items-center gap-3 rounded-lg bg-surface px-3 py-3 shadow-[var(--shadow-border)]"
                >
                  <Sigil ship={pal.ship} size={36} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-mono text-sm">{pal.ship}</p>
                    <p className="font-mono text-[11px] text-subtle">
                      {pal.target && pal.leech ? "mutual" : pal.target ? "target" : "leech"}
                      {pal.connection ? ` · ${pal.connection}` : ""}
                      {DISPLAY_NAMES[pal.ship] ? ` · ${DISPLAY_NAMES[pal.ship]}` : ""}
                    </p>
                  </div>
                  {pal.target ? (
                    <Button type="button" size="sm" variant="ghost" onClick={() => part(pal.ship)}>
                      Part
                    </Button>
                  ) : (
                    <Button type="button" size="sm" variant="ghost" onClick={() => addPal(pal.ship)}>
                      Add back
                    </Button>
                  )}
                </li>
              ))}
            </ul>
          )}


        </section>

        <ol className="order-4 space-y-3 lg:order-none">
          {log.slice(0, 40).map((ev) => (
            <li
              key={ev.id}
              className="flex gap-3 rounded-lg bg-surface px-3 py-3 shadow-[var(--shadow-border)]"
            >
              {ev.ship ? <Sigil ship={ev.ship} size={28} /> : <div className="size-7 rounded-sm bg-raised" />}
              <div className="min-w-0">
                <p className="font-mono text-[11px] text-subtle">
                  %{ev.kind}
                  {ev.hop != null ? ` · hop ${ev.hop}` : ""}
                </p>
                <p className="mt-0.5 text-sm text-fg">{ev.note}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>

      <aside className="order-2 h-fit rounded-xl bg-surface p-5 shadow-[var(--shadow-border)] lg:sticky lg:top-8 lg:order-none">
        <h2 className="font-display text-xl italic">config</h2>
        <p className="mt-1 text-sm text-muted">
          {plugins.length} listings · {connected} connected pals
        </p>

        <label className="mt-6 block">
          <span className="font-mono text-[11px] text-subtle uppercase">publication hops {config.hops}</span>
          <input
            type="range"
            min={0}
            max={3}
            value={config.hops}
            onChange={(e) => setConfig({ hops: Number(e.target.value) })}
            className="mt-2 w-full accent-accent"
          />
          <span className="mt-1 block text-xs text-muted">
            {config.hops === 0
              ? "New publications stay local. Existing withdrawals still propagate."
              : config.hops === 1
                ? "Direct pals only. The live default."
                : config.hops === 2
                  ? "Pals of pals."
                  : "Your new publications can travel three hops."}
          </span>
        </label>

        <fieldset className="mt-6">
          <legend className="font-mono text-[11px] text-subtle uppercase">hear</legend>
          <div className="mt-2 flex flex-col gap-1">
            {(["anybody", "targets", "mutuals"] as HearMode[]).map((mode) => (
              <ModeButton
                key={mode}
                active={config.hear === mode}
                onClick={() => setConfig({ hear: mode })}
              >
                {`%${mode}`}
              </ModeButton>
            ))}
          </div>
        </fieldset>

        <fieldset className="mt-6">
          <legend className="font-mono text-[11px] text-subtle uppercase">tell</legend>
          <div className="mt-2 flex flex-col gap-1">
            {(["anybody", "targets", "mutuals"] as HearMode[]).map((mode) => (
              <ModeButton
                key={mode}
                active={config.tell === mode}
                onClick={() => setConfig({ tell: mode })}
              >
                {`%${mode}`}
              </ModeButton>
            ))}
          </div>
        </fieldset>

        <p className="mt-2 text-xs leading-relaxed text-muted">
          Changing publication hops affects your next publication. It does not reset the hop
          budget of listings you relay. The original publisher’s signature stays attached.
        </p>
      </aside>
    </div>
  );
}

function ModeButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "h-10 rounded-md px-3 text-left font-mono text-xs transition-colors duration-150",
        active ? "bg-accent text-accent-fg" : "bg-raised text-muted hover:text-fg",
      )}
    >
      {children}
    </button>
  );
}
