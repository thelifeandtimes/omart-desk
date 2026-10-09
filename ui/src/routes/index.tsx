import { createFileRoute } from "@tanstack/react-router";
import { Search } from "lucide-react";
import type { ReactNode } from "react";
import { useMemo, useState } from "react";
import { PluginCard } from "@/components/plugin-card";
import { Input } from "@/components/ui/input";
import { useOmart } from "@/lib/omart/store";
import { CATEGORIES, KINDS, listingKey, type Category, type PluginKind } from "@/lib/omart/types";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/")({ component: Bazaar });

function Bazaar() {
  const plugins = useOmart((s) => s.plugins);
  const saved = useOmart((s) => s.saved);
  const [q, setQ] = useState("");
  const [kind, setKind] = useState<PluginKind | "all">("all");
  const [category, setCategory] = useState<Category | "all">("all");
  const [onlySaved, setOnlySaved] = useState(false);

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return plugins.filter((p) => {
      if (onlySaved && !saved.has(listingKey(p))) return false;
      if (kind !== "all" && !p.kinds.includes(kind)) return false;
      if (category !== "all" && p.category !== category) return false;
      if (!needle) return true;
      return (
        p.name.toLowerCase().includes(needle) ||
        p.id.toLowerCase().includes(needle) ||
        p.author.toLowerCase().includes(needle) ||
        p.description.toLowerCase().includes(needle) ||
        p.tags.some((t) => t.includes(needle))
      );
    });
  }, [plugins, q, kind, category, onlySaved, saved]);

  return (
    <div>
      <header className="max-w-2xl">
        <p className="font-mono text-[11px] tracking-wide text-subtle uppercase">%omart</p>
        <h1 className="mt-2 font-display text-4xl leading-tight tracking-tight italic md:text-5xl">
          Plugins that reach you
        </h1>
        <p className="mt-3 max-w-xl text-sm leading-relaxed text-muted md:text-[15px]">
          Signed listings travel through %pals, keeping their original publisher’s identity.
          Your pals share discoveries within each publisher’s hop limit and relay signed withdrawals.
        </p>
      </header>

      <div className="relative mt-8 max-w-xl">
        <Search className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-subtle" />
        <Input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search name, id, author, tag"
          className="pl-10"
          aria-label="Search plugins"
        />
      </div>

      <div className="mt-4 flex flex-wrap gap-2">
        <FilterChip active={!onlySaved && kind === "all" && category === "all"} onClick={() => { setKind("all"); setCategory("all"); setOnlySaved(false); }}>
          All {plugins.length}
        </FilterChip>
        <FilterChip active={onlySaved} onClick={() => setOnlySaved((v) => !v)}>
          Saved
        </FilterChip>
        {KINDS.map((k) => (
          <FilterChip key={k} active={kind === k} onClick={() => setKind(kind === k ? "all" : k)}>
            {k}
          </FilterChip>
        ))}
      </div>
      <div className="mt-2 flex flex-wrap gap-2">
        {CATEGORIES.map((c) => (
          <FilterChip key={c} active={category === c} onClick={() => setCategory(category === c ? "all" : c)}>
            {c}
          </FilterChip>
        ))}
      </div>

      {filtered.length === 0 ? (
        <p className="mt-16 max-w-md text-sm text-muted">
          No matching listings. Add pals or use Sync listings on the Pals page to catch up.
        </p>
      ) : (
        <div className="mt-8 grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {filtered.map((plugin, i) => (
            <PluginCard key={listingKey(plugin)} plugin={plugin} delay={Math.min(i, 12) * 40} />
          ))}
        </div>
      )}
    </div>
  );
}

function FilterChip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "h-8 rounded-full px-3 font-mono text-[11px] transition-colors duration-150",
        active ? "bg-accent text-accent-fg" : "bg-raised text-muted shadow-[var(--shadow-border)] hover:text-fg",
      )}
    >
      {children}
    </button>
  );
}
