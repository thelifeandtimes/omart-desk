import { create } from "zustand";
import { OUR_SHIP } from "./ships";
import {
  DEFAULT_CONFIG,
  KINDS,
  LISTING_ID_HELP,
  validListingId,
  listingKey,
  type GossipConfig,
  type GossipEvent,
  type HeardPlugin,
  type HearMode,
  type PalRecord,
  type PalsStatus,
  type PluginKind,
  type PluginListing,
  type Ship,
} from "./types";

const STORAGE_KEY = "omart.pier.v3";
const API = "/omart";
const HDRS = { "content-type": "application/json", "x-omart": "1" };

type PersistShape = {
  saved: string[];
  log: GossipEvent[];
};

type OmartState = {
  hydrated: boolean;
  our: Ship;
  pals: PalRecord[];
  palsStatus: PalsStatus | null;
  palsError: string | null;
  plugins: HeardPlugin[];
  saved: Set<string>;
  config: GossipConfig;
  log: GossipEvent[];
  hydrate: () => void;
  refresh: () => Promise<void>;
  installPals: () => Promise<string | null>;
  retryConnections: () => Promise<string | null>;
  meet: (who: Ship) => Promise<string | null>;
  part: (who: Ship) => Promise<string | null>;
  toggleSave: (id: string) => void;
  publish: (listing: Omit<PluginListing, "origin">) => Promise<string | null>;
  retract: (id: string) => Promise<string | null>;
  setConfig: (patch: Partial<GossipConfig>) => Promise<string | null>;
};

function asPal(raw: unknown): PalRecord | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as { ship?: unknown; target?: unknown; leech?: unknown; connection?: unknown };
  if (typeof o.ship !== "string" || !o.ship.startsWith("~")) return null;
  const pal: PalRecord = { ship: o.ship, target: !!o.target, leech: !!o.leech };
  if (o.connection === "connected" || o.connection === "connecting" || o.connection === "disconnected") {
    pal.connection = o.connection;
  }
  return pal;
}

function asPalsStatus(raw: unknown): PalsStatus | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  if (!["missing", "installing", "waiting", "starting", "suspended", "ready"].includes(String(o.phase))) return null;
  return { phase: o.phase as PalsStatus["phase"], source: typeof o.source === "string" ? o.source : null };
}

function asKind(t: unknown): PluginKind | null {
  return typeof t === "string" && (KINDS as string[]).includes(t) ? (t as PluginKind) : null;
}

function asListing(raw: unknown, our: Ship): HeardPlugin | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  if (typeof o.id !== "string" || typeof o.name !== "string") return null;
  if (typeof o.git !== "string" || typeof o.ship !== "string") return null;
  const kinds = Array.isArray(o.kinds) ? o.kinds.map(asKind).filter((k): k is PluginKind => k !== null) : [];
  const origin = o.ship.startsWith("~") ? o.ship : our;
  const local = origin === our;
  return {
    id: o.id,
    name: o.name,
    version: typeof o.version === "string" ? o.version : "0.1.0",
    author: typeof o.author === "string" ? o.author : "",
    origin,
    description: typeof o.description === "string" ? o.description : "",
    git: o.git,
    kinds,
    tags: Array.isArray(o.tags) ? o.tags.filter((t): t is string => typeof t === "string") : [],
    category: "tools",
    license: "MIT",
    hop: typeof o.hop === "number" ? o.hop : local ? 0 : -1,
    path: local ? [our] : [],
    heardAt: 0,
    local,
    verified: o.verified === true,
    via: typeof o.via === "string" ? o.via : undefined,
    revision: typeof o.revision === "string" ? o.revision : undefined,
  };
}

function asConfig(raw: unknown): GossipConfig | null {
  if (!raw || typeof raw !== "object") return null;
  const o = raw as Record<string, unknown>;
  const hear = o.hear;
  const tell = o.tell;
  const modes: HearMode[] = ["anybody", "targets", "mutuals"];
  if (typeof o.hops !== "number") return null;
  if (typeof hear !== "string" || !modes.includes(hear as HearMode)) return null;
  if (typeof tell !== "string" || !modes.includes(tell as HearMode)) return null;
  return {
    hops: Math.max(0, Math.min(3, Math.floor(o.hops))),
    hear: hear as HearMode,
    tell: tell as HearMode,
    pass: false,
  };
}

async function api<T>(path: string, init?: RequestInit): Promise<{ ok: true; data: T } | { ok: false; error: string; status: number }> {
  try {
    const r = await fetch(`${API}${path}`, { credentials: "include", ...init, headers: { ...HDRS, ...(init?.headers ?? {}) } });
    const text = await r.text();
    let data: unknown = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = null;
    }
    if (!r.ok) {
      const err =
        data && typeof data === "object" && "error" in data && typeof (data as { error: unknown }).error === "string"
          ? (data as { error: string }).error
          : r.statusText || "request failed";
      return { ok: false, error: err, status: r.status };
    }
    return { ok: true, data: data as T };
  } catch {
    return { ok: false, error: "Could not reach this ship. Try again.", status: 0 };
  }
}

function persist(partial: PersistShape) {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(partial));
}

function event(
  kind: GossipEvent["kind"],
  note: string,
  extra: Partial<GossipEvent> = {},
): GossipEvent {
  return {
    id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    at: Date.now(),
    kind,
    note,
    ...extra,
  };
}

export const useOmart = create<OmartState>((set, get) => ({
  hydrated: false,
  our: OUR_SHIP,
  pals: [],
  palsStatus: null,
  palsError: null,
  plugins: [],
  saved: new Set(),
  config: DEFAULT_CONFIG,
  log: [],

  hydrate: () => {
    if (get().hydrated) return;
    let saved = new Set<string>();
    let log: GossipEvent[] = [];
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const loaded = JSON.parse(raw) as PersistShape;
        saved = new Set(loaded.saved ?? []);
        log = loaded.log ?? [];
      }
    } catch {
      /* ignore */
    }
    set({ saved, log });
    void get().refresh().then(() => set({ hydrated: true }));
  },

  refresh: async () => {
    const ourGuess = get().our;
    const [palsRes, listRes, cfgRes] = await Promise.all([
      api<{ our?: string; pals?: unknown[]; status?: unknown } | null>("/pals.json"),
      api<unknown[]>("/listings.json"),
      api<unknown>("/config.json"),
    ]);
    const our =
      palsRes.ok && typeof palsRes.data?.our === "string" && palsRes.data.our.startsWith("~")
        ? palsRes.data.our
        : ourGuess;
    const pals = palsRes.ok && Array.isArray(palsRes.data?.pals)
      ? palsRes.data.pals.map(asPal).filter((p): p is PalRecord => p !== null)
      : get().pals;
    const plugins = listRes.ok && Array.isArray(listRes.data)
      ? listRes.data.map((row) => asListing(row, our)).filter((p): p is HeardPlugin => p !== null)
      : get().plugins;
    const config = cfgRes.ok ? asConfig(cfgRes.data) ?? get().config : get().config;
    const palsStatus = palsRes.ok ? asPalsStatus(palsRes.data?.status) : null;
    const palsError = palsRes.ok
      ? palsStatus ? null : "Could not read %pals status. Check that the Omart agent is up to date and that you are logged in."
      : palsRes.error;
    // Move old ID-only bookmarks into the publisher namespace once known.
    const previousSaved = get().saved;
    const saved = new Set(previousSaved);
    let migrated = false;
    for (const plugin of plugins) {
      if (previousSaved.has(plugin.id)) {
        saved.delete(plugin.id);
        saved.add(listingKey(plugin));
        migrated = true;
      }
    }
    set({ our, pals, plugins, config, palsStatus, palsError, saved });
    if (migrated) persist({ saved: [...saved], log: get().log });
  },

  installPals: async () => {
    const res = await api("/install-pals", { method: "POST", body: "{}" });
    if (!res.ok) return res.error;
    await get().refresh();
    return null;
  },

  retryConnections: async () => {
    const res = await api("/retry", { method: "POST", body: "{}" });
    if (!res.ok) return res.error;
    await get().refresh();
    return null;
  },

  meet: async (who) => {
    const { our, pals } = get();
    if (who === our) return "that is this ship";
    if (pals.some((p) => p.ship === who && p.target)) return null;
    const res = await api("/meet", { method: "POST", body: JSON.stringify({ ship: who }) });
    if (!res.ok) return res.error;
    const previous = get().pals.find((p) => p.ship === who);
    const pal: PalRecord = { ship: who, target: true, leech: previous?.leech ?? false };
    const log = [event("meet", `target ${who}`, { ship: who }), ...get().log];
    set({ pals: [...get().pals.filter((p) => p.ship !== who), pal], log });
    persist({ saved: [...get().saved], log });
    void get().refresh();
    return null;
  },

  part: async (who) => {
    const res = await api("/part", { method: "POST", body: JSON.stringify({ ship: who }) });
    if (!res.ok) return res.error;
    const log = [event("part", `parted ${who}`, { ship: who }), ...get().log];
    set({ pals: get().pals.filter((p) => p.ship !== who), log });
    persist({ saved: [...get().saved], log });
    void get().refresh();
    return null;
  },

  toggleSave: (id) => {
    const saved = new Set(get().saved);
    if (saved.has(id)) saved.delete(id);
    else saved.add(id);
    set({ saved });
    persist({ saved: [...saved], log: get().log });
  },

  publish: async (input) => {
    if (!validListingId(input.id)) return LISTING_ID_HELP;
    const res = await api<unknown>("/publish", {
      method: "POST",
      body: JSON.stringify({
        id: input.id,
        name: input.name,
        git: input.git,
        description: input.description,
        version: input.version,
        author: input.author,
        kinds: input.kinds,
        tags: input.tags,
      }),
    });
    if (!res.ok) return res.error;
    const log = [event("publish", `publish ${input.id}`, { pluginId: input.id, hop: 0, ship: get().our }), ...get().log];
    const saved = new Set(get().saved);
    saved.add(listingKey({ id: input.id, origin: get().our }));
    set({ log, saved });
    persist({ saved: [...saved], log });
    await get().refresh();
    return null;
  },

  retract: async (id) => {
    const res = await api("/retract", { method: "POST", body: JSON.stringify({ id }) });
    if (!res.ok) return res.error;
    const log = [event("publish", `retract ${id}`, { pluginId: id, ship: get().our }), ...get().log];
    const saved = new Set(get().saved);
    saved.delete(listingKey({ id, origin: get().our }));
    set({
      plugins: get().plugins.filter((p) => p.id !== id || p.origin !== get().our),
      saved,
      log,
    });
    persist({ saved: [...saved], log });
    await get().refresh();
    return null;
  },

  setConfig: async (patch) => {
    const config = { ...get().config, ...patch, pass: false };
    const res = await api("/config", { method: "POST", body: JSON.stringify(config) });
    if (!res.ok) return res.error;
    const next = asConfig(res.ok ? (res as { data: unknown }).data : null) ?? config;
    const log = [
      event("config", `hops=${next.hops} hear=${next.hear} tell=${next.tell}`),
      ...get().log,
    ];
    set({ config: next, log });
    persist({ saved: [...get().saved], log });
    return null;
  },
}));
