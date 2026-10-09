import { cn } from "@/lib/utils";

export function HopBadge({ hop, className }: { hop: number; className?: string }) {
  const label = hop < 0 ? "legacy" : hop === 0 ? "local" : hop === 1 ? "pal" : `hop ${hop}`;
  return (
    <span
      className={cn(
        "inline-flex h-6 items-center rounded-full px-2 font-mono text-[11px] tabular-nums tracking-wide",
        hop === 0 ? "bg-accent text-accent-fg" : "bg-raised text-muted shadow-[var(--shadow-border)]",
        className,
      )}
    >
      {label}
    </span>
  );
}

export function KindBadge({ kind }: { kind: string }) {
  return (
    <span className="inline-flex h-6 items-center rounded-full bg-raised px-2 font-mono text-[11px] text-muted shadow-[var(--shadow-border)]">
      {kind}
    </span>
  );
}
