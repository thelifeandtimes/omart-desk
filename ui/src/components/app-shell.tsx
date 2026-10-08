import { Link, useRouterState } from "@tanstack/react-router";
import { Store, Upload, Users } from "lucide-react";
import type { ReactNode } from "react";
import { useEffect } from "react";
import { Sigil } from "@/components/sigil";
import { useOmart } from "@/lib/omart/store";
import { cn } from "@/lib/utils";

const NAV = [
  { to: "/", label: "Bazaar", icon: Store },
  { to: "/pals", label: "Pals", icon: Users },
  { to: "/publish", label: "Publish", icon: Upload },
] as const;

export function AppShell({ children }: { children: ReactNode }) {
  const hydrate = useOmart((s) => s.hydrate);
  const refresh = useOmart((s) => s.refresh);
  const hydrated = useOmart((s) => s.hydrated);
  const our = useOmart((s) => s.our);
  const plugins = useOmart((s) => s.plugins);
  const pals = useOmart((s) => s.pals);
  const pathname = useRouterState({ select: (s) => s.location.pathname });

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  useEffect(() => {
    if (!hydrated) return;
    let pending = false;
    const update = async () => {
      if (document.hidden || pending) return;
      pending = true;
      try {
        await refresh();
      } catch {
        // Keep the last catalog while the ship is temporarily unreachable.
      } finally {
        pending = false;
      }
    };
    const timer = window.setInterval(update, 5000);
    window.addEventListener("focus", update);
    document.addEventListener("visibilitychange", update);
    return () => {
      window.clearInterval(timer);
      window.removeEventListener("focus", update);
      document.removeEventListener("visibilitychange", update);
    };
  }, [hydrated, refresh]);

  if (!hydrated) {
    return <div className="min-h-dvh bg-bg" aria-hidden />;
  }

  return (
    <div className="min-h-dvh bg-bg text-fg">
      <aside className="fixed top-0 bottom-0 left-0 z-20 hidden w-56 flex-col border-r border-border bg-bg px-4 py-6 md:flex">
        <Link to="/" className="flex items-center gap-3 px-2">
          <Sigil ship={our} size={36} />
          <div className="min-w-0">
            <p className="font-display text-2xl leading-none tracking-tight italic">omart</p>
            <p className="mt-1 truncate font-mono text-[11px] text-subtle">{our}</p>
          </div>
        </Link>
        <nav className="mt-10 flex flex-1 flex-col gap-1">
          {NAV.map((item) => {
            const active = item.to === "/" ? pathname === "/" : pathname.startsWith(item.to);
            const Icon = item.icon;
            return (
              <Link
                key={item.to}
                to={item.to}
                className={cn(
                  "flex h-11 items-center gap-3 rounded-md px-3 text-sm transition-colors duration-150",
                  active ? "bg-raised text-fg" : "text-muted hover:bg-raised hover:text-fg",
                )}
              >
                <Icon className="size-4" strokeWidth={1.75} />
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="mt-auto space-y-3 px-2">
          <div className="font-mono text-[11px] text-subtle">
            <p className="tabular-nums">{plugins.length} listings</p>
            <p className="tabular-nums">{pals.length} pals</p>
          </div>
        </div>
      </aside>

      <header className="sticky top-0 z-20 flex items-center justify-between border-b border-border bg-bg/95 px-4 py-3 backdrop-blur-sm md:hidden">
        <Link to="/" className="flex items-center gap-2">
          <Sigil ship={our} size={28} />
          <span className="font-display text-xl italic tracking-tight">omart</span>
        </Link>
      </header>

      <main className="md:pl-56">
        <div className="mx-auto w-full max-w-6xl px-4 pt-6 pb-28 md:px-8 md:pt-10 md:pb-16">{children}</div>
      </main>

      <nav className="fixed right-0 bottom-0 left-0 z-20 grid grid-cols-3 border-t border-border bg-bg/95 backdrop-blur-sm md:hidden">
        {NAV.map((item) => {
          const active = item.to === "/" ? pathname === "/" : pathname.startsWith(item.to);
          const Icon = item.icon;
          return (
            <Link
              key={item.to}
              to={item.to}
              className={cn(
                "flex min-h-14 flex-col items-center justify-center gap-1 text-[11px]",
                active ? "text-fg" : "text-subtle",
              )}
            >
              <Icon className="size-4" strokeWidth={1.75} />
              {item.label}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
