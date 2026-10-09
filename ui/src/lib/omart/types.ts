export type PluginKind =
  | "bar-widget"
  | "panel"
  | "overlay"
  | "menu"
  | "service"
  | "bar";

export type Category =
  | "tools"
  | "media"
  | "weather"
  | "desktop"
  | "homelab"
  | "dev"
  | "news"
  | "theme"
  | "status";

export type HearMode = "anybody" | "targets" | "mutuals";

export type GossipConfig = {
  hops: number;
  hear: HearMode;
  tell: HearMode;
  pass: boolean;
};

export type Ship = string;

export type PalRecord = {
  ship: Ship;
  /** we added them */
  target: boolean;
  /** they added us */
  leech: boolean;
  connection?: "connected" | "connecting" | "disconnected";
};

export type PalsStatus = {
  phase: "missing" | "installing" | "waiting" | "starting" | "suspended" | "ready";
  source: Ship | null;
};

export const LISTING_ID_PATTERN = "[a-z][a-z0-9-]*";
export const LISTING_ID_HELP = "Start with a lowercase letter; use lowercase letters, digits, and hyphens (no periods).";

export function validListingId(id: string) {
  return new RegExp(`^${LISTING_ID_PATTERN}$`).test(id);
}

export type PluginListing = {
  id: string;
  name: string;
  version: string;
  author: string;
  origin: Ship;
  description: string;
  git: string;
  kinds: PluginKind[];
  tags: string[];
  category: Category;
  license: string;
};

export type HeardPlugin = PluginListing & {
  hop: number;
  path: Ship[];
  heardAt: number;
  local: boolean;
};

export type GossipEvent = {
  id: string;
  at: number;
  kind: "heard" | "publish" | "meet" | "part" | "hey" | "config" | "pass";
  ship?: Ship;
  pluginId?: string;
  hop?: number;
  note: string;
};

export const KINDS: PluginKind[] = [
  "bar-widget",
  "panel",
  "overlay",
  "menu",
  "service",
  "bar",
];

export const CATEGORIES: Category[] = [
  "tools",
  "media",
  "weather",
  "desktop",
  "homelab",
  "dev",
  "news",
  "theme",
  "status",
];

export const DEFAULT_CONFIG: GossipConfig = {
  hops: 1,
  hear: "targets",
  tell: "targets",
  pass: false,
};

export function installCommand(git: string) {
  return `omarchy plugin add ${git} --enable`;
}
