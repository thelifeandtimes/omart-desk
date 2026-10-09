import { Link } from "@tanstack/react-router";
import { HopBadge, KindBadge } from "@/components/hop-badge";
import { PluginMark } from "@/components/plugin-mark";
import { Sigil } from "@/components/sigil";
import type { HeardPlugin } from "@/lib/omart/types";

export function PluginCard({ plugin, delay = 0 }: { plugin: HeardPlugin; delay?: number }) {
  return (
    <Link
      to="/plugin/$id"
      params={{ id: plugin.id }}
      search={{ ship: plugin.origin }}
      className="group flex flex-col rounded-xl bg-surface p-2 shadow-[var(--shadow-border)] transition-[box-shadow,transform] duration-200 ease-out hover:shadow-[var(--shadow-border-hover)] motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2"
      style={{ animationDelay: `${delay}ms`, animationFillMode: "both" }}
    >
      <div className="relative aspect-[5/3] overflow-hidden rounded-lg bg-raised">
        <PluginMark id={plugin.id} />
        <div className="absolute top-2 left-2">
          <HopBadge hop={plugin.hop} />
        </div>
      </div>
      <div className="flex flex-1 flex-col gap-2 px-2 pt-3 pb-2">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h2 className="font-display text-lg leading-snug tracking-tight text-fg">{plugin.name}</h2>
            <p className="mt-0.5 font-mono text-[11px] text-subtle">{plugin.id}</p>
            <p className="mt-1 font-mono text-[11px] text-muted">{plugin.origin} · {plugin.verified ? "signed" : "legacy, unverified"}</p>
          </div>
          <Sigil ship={plugin.origin} size={28} />
        </div>
        <p className="line-clamp-2 text-sm leading-relaxed text-muted">{plugin.description}</p>
        <div className="mt-auto flex flex-wrap gap-1.5 pt-1">
          {plugin.kinds.slice(0, 3).map((k) => (
            <KindBadge key={k} kind={k} />
          ))}
        </div>
      </div>
    </Link>
  );
}
