import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowLeft, Bookmark, BookmarkCheck, ExternalLink } from "lucide-react";
import { CommandCopy } from "@/components/command-copy";
import { HopBadge, KindBadge } from "@/components/hop-badge";
import { PluginMark } from "@/components/plugin-mark";
import { Sigil } from "@/components/sigil";
import { Button } from "@/components/ui/button";
import { DISPLAY_NAMES } from "@/lib/omart/ships";
import { useOmart } from "@/lib/omart/store";
import { listingKey } from "@/lib/omart/types";

export const Route = createFileRoute("/plugin/$id")({
  validateSearch: (search: Record<string, unknown>): { ship?: string } => ({
    ship: typeof search.ship === "string" ? search.ship : undefined,
  }),
  component: PluginPage,
});

function PluginPage() {
  const { id } = Route.useParams();
  const { ship } = Route.useSearch();
  const plugins = useOmart((s) => s.plugins);
  const matches = plugins.filter((p) => p.id === id);
  const plugin = ship ? matches.find((p) => p.origin === ship) : matches.length === 1 ? matches[0] : undefined;
  const saved = useOmart((s) => plugin ? s.saved.has(listingKey(plugin)) : false);
  const toggleSave = useOmart((s) => s.toggleSave);
  const retract = useOmart((s) => s.retract);
  const our = useOmart((s) => s.our);

  if (!ship && matches.length > 1) {
    return <section className="max-w-lg">
      <h1 className="font-display text-3xl italic">Choose a publisher</h1>
      <p className="mt-3 text-sm text-muted">More than one ship publishes a listing named {id}.</p>
      <ul className="mt-5 space-y-3">{matches.map((p) => <li key={listingKey(p)}>
        <Link to="/plugin/$id" params={{ id }} search={{ ship: p.origin }} className="font-mono text-sm underline">{p.origin}</Link>
      </li>)}</ul>
    </section>;
  }

  if (!plugin) {
    return (
      <div className="max-w-lg">
        <p className="font-mono text-xs text-subtle">not in range</p>
        <h1 className="mt-2 font-display text-3xl italic">This listing has not reached you</h1>
        <p className="mt-3 text-sm text-muted">
          It may have been withdrawn, be beyond its publisher’s hop limit, or not have reached
          your pals yet. Use Sync listings on the Pals page to catch up.
        </p>
        <Button asChild variant="secondary" className="mt-6">
          <Link to="/">Back to bazaar</Link>
        </Button>
      </div>
    );
  }

  return (
    <article className="max-w-3xl">
      <Link
        to="/"
        className="inline-flex h-11 items-center gap-2 text-sm text-muted hover:text-fg"
      >
        <ArrowLeft className="size-4" />
        Bazaar
      </Link>

      <div className="mt-6 overflow-hidden rounded-xl bg-surface p-2 shadow-[var(--shadow-border)]">
        <div className="aspect-[2/1] overflow-hidden rounded-lg bg-raised md:aspect-[5/2]">
          <PluginMark id={plugin.id} />
        </div>
      </div>

      <div className="mt-8 flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <HopBadge hop={plugin.hop} />
            {plugin.kinds.map((k) => (
              <KindBadge key={k} kind={k} />
            ))}
          </div>
          <h1 className="mt-3 font-display text-4xl tracking-tight italic">{plugin.name}</h1>
          <p className="mt-2 font-mono text-xs text-subtle">{plugin.id} · {plugin.version} · {plugin.license}</p>
        </div>
        <Button
          type="button"
          variant={saved ? "default" : "secondary"}
          onClick={() => toggleSave(listingKey(plugin))}
        >
          {saved ? <BookmarkCheck /> : <Bookmark />}
          {saved ? "Saved" : "Keep"}
        </Button>
      </div>

      <p className="mt-5 max-w-2xl text-[15px] leading-relaxed text-muted">{plugin.description}</p>

      <section className="mt-8">
        <h2 className="font-mono text-[11px] tracking-wide text-subtle uppercase">Install</h2>
        <p className="mt-2 text-sm text-muted">
          Plugins run unsandboxed inside omarchy-shell. Read the repo before you enable one.
        </p>
        <CommandCopy git={plugin.git} className="mt-3" />
        <a
          href={plugin.git.replace(/\.git$/, "")}
          target="_blank"
          rel="noreferrer"
          className="mt-3 inline-flex h-11 items-center gap-2 text-sm text-muted hover:text-fg"
        >
          <ExternalLink className="size-4" />
          Source
        </a>
      </section>

      <section className="mt-10">
        <h2 className="font-mono text-[11px] tracking-wide text-subtle uppercase">Publisher</h2>
        <div className="mt-4 flex items-center gap-2"><Sigil ship={plugin.origin} size={28} />
          <span className="font-mono text-sm">{plugin.origin}</span>
        </div>
        <p className="mt-3 text-sm text-muted">
          {plugin.verified ? "Signature verified against the publisher’s Urbit identity." :
            "Legacy listing: its claimed publisher has not yet supplied a signed update. This copy is not relayed."}
          {plugin.verified && !plugin.local && plugin.via ? ` Received via ${plugin.via}, ${plugin.hop} hop${plugin.hop === 1 ? "" : "s"} from the publisher.` : ""}
          {DISPLAY_NAMES[plugin.origin] ? ` (${DISPLAY_NAMES[plugin.origin]})` : ""}
        </p>
      </section>

      <dl className="mt-10 grid gap-4 sm:grid-cols-2">
        <div>
          <dt className="font-mono text-[11px] text-subtle uppercase">Author</dt>
          <dd className="mt-1 text-sm">{plugin.author}</dd>
        </div>
        <div>
          <dt className="font-mono text-[11px] text-subtle uppercase">Origin</dt>
          <dd className="mt-1 font-mono text-sm">{plugin.origin}</dd>
        </div>
        <div>
          <dt className="font-mono text-[11px] text-subtle uppercase">Category</dt>
          <dd className="mt-1 text-sm">{plugin.category}</dd>
        </div>
        <div>
          <dt className="font-mono text-[11px] text-subtle uppercase">Tags</dt>
          <dd className="mt-1 text-sm text-muted">{plugin.tags.join(" · ")}</dd>
        </div>
      </dl>

      {plugin.origin === our && (
        <Button type="button" variant="ghost" className="mt-10 text-danger" onClick={() => void retract(plugin.id)}>
          Retract listing
        </Button>
      )}
    </article>
  );
}
