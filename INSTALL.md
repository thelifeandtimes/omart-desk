# Install and publish %omart

Kelvin: `[%zuse 408]`. Change `desk/sys.kelvin` if your ship is on a newer `%zuse`.

Requires **%pals**. If needed:

```
|install ~paldev %pals
```

The built UI lives in `desk/web/`. `|install ~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod %omart` copies the agent and that UI together. Friends do not run `npm`.

## On the publisher

The original public publisher is the mined comet `~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod`, pier `/home/ahlmark/urbit/comet`.

Create and mount the desk if it is new:

```
|new-desk %omart
|mount %omart
```

For your own distribution ship, substitute its pier path below. From a clone of
this fork:

```
git clone --branch codex/fix-sharing-fakenet https://github.com/thelifeandtimes/omart-desk.git
cd omart-desk
sh scripts/install-to-pier.sh /home/ahlmark/urbit/comet
```

That copies **only** `desk/` into `$PIER/omart` (including `desk/web/`). Then in the dojo:

```
|commit %omart
|install our %omart
:treaty|publish %omart
```

Do not copy `sys.kelvin` over a live ship's kelvin; the install script leaves the pier's file in place.

## Upgrade an existing publisher

From this checkout, with `%base` and `%omart` mounted on your chosen pier:

```sh
sh scripts/install-to-pier.sh /absolute/path/to/your/pier
```

Then in that ship's dojo:

```hoon
|commit %omart
```

An already-installed agent reloads automatically. Existing desk subscribers
receive the update from their distribution ship; an already-published desk does
not need a new treaty publication. Reload open browser tabs to load the new UI.

This version migrates the agent's state and automatically signs existing local
publications and remembered local withdrawals. Existing pals and hear/tell/hop
settings are preserved; the anonymous proxy setting is removed. Other ships'
legacy cache entries remain explicitly unverified until their origins supply
signed updates. Publishers and relays must all upgrade to exchange signed
records. Use **Sync listings** or `:omart &omart-action [%retry ~]` afterward.
The default one-hop limit is unchanged; choose two or three hops and republish
if you want an existing listing to travel further.

Keep a complete pre-upgrade pier backup if you need rollback. The old agent cannot
load the new version-2 state. Details and limitations are in
[Signed sharing](docs/SHARING.md).

## For friends

They need `%pals`, then:

```
|install ~pilryg-tanmus-hopsec-mitwel--nodreb-sigtul-falhut-samzod %omart
```

Landscape opens `/apps/omart`. The tile, left nav, Bazaar, Pals, and Publish screens are the same bundle you ship in `desk/web/`. Their pals list and gossiped listings are from their ship.

## Rebuild the UI (publisher only)

After changing `ui/`:

```
sh scripts/sync-ui-into-desk.sh
sh scripts/install-to-pier.sh /home/ahlmark/urbit/comet
```

Then `|commit %omart` again.

## Gossip defaults

hops 1, hear/tell `%targets`. Change them in the Pals page; that pokes Gall.
Publication hop limits do not restrict withdrawal propagation.
