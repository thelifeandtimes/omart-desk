<p align="center">
  <img src="desk/web/icon.svg" alt="Omart" width="96" />
</p>

<h1 align="center">Omart</h1>

<p align="center">
  Find and share Omarchy plugins from the ships you already talk to.
</p>

<p align="center">
  A gossip bazaar for Urbit. Listings travel along <code>%pals</code>, not a central catalog.<br />
  <a href="LICENSE">MIT</a>
</p>

## Install

In the dojo, on a ship that already has `%pals`:

```
|install ~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod %omart
```

If you do not have `%pals` yet, open Omart's Pals page and choose **Install %pals
from ~paldev**. It tracks the actual desk/agent state and opens your pal list once
the agent is running. You can also install it in the dojo:

```
|install ~paldev %pals
|install ~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod %omart
```

Open the Omart tile in Landscape. You get the same Bazaar, Pals, and Publish screens as the publisher. Your pal list and the listings you hear are your own.

Publishing the desk from your ship is in [INSTALL.md](INSTALL.md).

## A pal's listing is missing

With the defaults, both ships must add each other as pals, and the publisher
must have hops greater than zero. Installing Omart from a ship does not make it
a pal. The Pals page shows whether your subscription to each peer is connected.

Click **Retry connections**, or run this after installing the current version:

```hoon
:omart &omart-action [%retry ~]
```

This immediately retries missing subscriptions allowed by your hear setting,
without changing pals, settings, listings, or existing subscriptions. A rejected
watch otherwise waits up to 30 minutes for the next automatic retry. If already
connected, the command leaves that connection alone.

For an older Omart version, change **hear** to another mode and then restore your
original mode to trigger reconciliation. To check installations manually:

```hoon
+vats %omart
+vats %pals
```

Listing IDs use lowercase letters, digits, and hyphens, beginning with a letter:
`yourname-plugin`. This is an Omart catalog key, separate from the plugin's
`manifest.json` ID (which may contain a period). Omarchy installs the repository
using its Git URL and manifest.

## What you get

- A Landscape tile at `/apps/omart` with Bazaar, Pals, and Publish.
- Listings that hop along the ships you have added as pals. The default is one hop, hear and tell limited to those pals, pass off.
- Publish and retract from the ship you are logged into. A retract is gossiped, so pals drop the listing too.
- Meet and part write to the `%pals` agent already on the ship. Omart does not ship its own pals agent.

## Why

Omarchy plugins live in git repos scattered across the network. Omart lets a ship publish a listing once and have it arrive at pals, instead of everyone keeping a private bookmark list.

## Backstory

Omart started as a desk for one ship, with a React client beside it. The desk and the UI are now one tree, so a friend can install both with `|install ~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod %omart`. The publisher copies `desk/` onto their pier, commits, and publishes. Friends do not run `npm`.

## For developers

The three-ship tmux development environment and sharing regression checks are
documented in [DEVELOPMENT.md](DEVELOPMENT.md).

| Path | What it is |
|---|---|
| `desk/` | Gall desk `%omart`, including the built UI in `desk/web/`. This is what `|install` ships. |
| `ui/` | Vite and React source. Rebuild with `sh scripts/sync-ui-into-desk.sh`. |
| `scripts/` | Copy the desk onto a mounted pier, or rebuild `desk/web/`. |
| `docs/` | Screenshot used above. |

```
desk/
  app/omart.hoon
  desk.bill            # ~[%omart]
  desk.docket-0        # Landscape tile, site /apps/omart
  sys.kelvin           # [%zuse 408]
  web/                 # index.html, css, and JS chunks
ui/                    # SPA source, base /apps/omart/
```

Kelvin in this repo is `[%zuse 408]`. If the publisher ship is on a newer `%zuse`, change `desk/sys.kelvin` before committing. The install script does not overwrite the pier's kelvin.

### API

The client talks to Gall at `/omart`. Mutating routes need a logged-in session, the header `x-omart: 1`, and an `Origin` that matches the ship.

| Method | Path | Auth |
|---|---|---|
| GET | `/omart/listings.json` | no |
| GET | `/omart/pals.json` | yes |
| GET | `/omart/config.json` | yes |
| POST | `/omart/publish` | yes |
| POST | `/omart/retract` | yes |
| POST | `/omart/meet` | yes |
| POST | `/omart/part` | yes |
| POST | `/omart/config` | yes |
| POST | `/omart/install-pals` | yes |
| POST | `/omart/retry` | yes |

`pals.json` includes `status: {phase, source}` for the dependency, plus each pal's
outgoing gossip `connection` (`connected`, `connecting`, or `disconnected`).
The install endpoint requests `%pals` from `~paldev` only when missing; it resumes
a suspended desk without changing its source, and is a no-op while installing
or already running. Its success acknowledges the request; poll `pals.json` for
completion. Requests rejected by Hood return an error.

Gossip defaults: hops 1, hear and tell `%targets`, pass off. The Pals page pokes Gall to change them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). How this project works with contributors is in the [anti-code of conduct](CODE_OF_CONDUCT.md). Report a security problem through [GitHub advisories](https://github.com/ahlmark/omart-desk/security/advisories/new), not a public issue. Details are in [SECURITY.md](SECURITY.md).
