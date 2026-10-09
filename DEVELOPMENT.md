# Local omart development

The development network runs in tmux session `omart-dev`. Its persistent piers
and dependency checkout live under `.dev/` (gitignored). These are fake ships;
HTTP and Ames bind to loopback. The existing `%tend` session and piers are separate.
The startup script uses `--snap-time 60` (one snapshot per 60 minutes) for both
new and resumed ships.

| Ship | Role | Omart |
|---|---|---|
| `~nec` | Publishes `%pals` and `%omart` | http://127.0.0.1:8091/apps/omart/ |
| `~bus` | Installs both desks from `~nec` | http://127.0.0.1:8092/apps/omart/ |
| `~tyr` | Installs both desks from `~nec` | http://127.0.0.1:8093/apps/omart/ |

The initial setup uses Vere 4.6, Zuse 408, and
[Fang-/suite](https://github.com/Fang-/suite) at
`b69ce154ae6ce906c2598cd46c806158b51b8a0f` for `%pals`.
All three ships are mutual pals with Omart's default configuration:
hops 1, hear/tell `%targets`.

## Daily work

```sh
scripts/fakenet.sh status
scripts/fakenet.sh start        # start missing ships, or resume their existing piers
tmux attach -t omart-dev
```

Each ship has its own named window. Run `+code` in that ship's dojo for its web
login code. Detach with tmux's normal detach key; the ships keep running.
Use `|exit` in a ship's dojo for a clean shutdown before restarting it.

After Hoon edits:

```sh
scripts/fakenet.sh sync
```

This copies the repository's `desk/` to `~nec` and queues `|commit %omart`.
Check the `nec` window for compilation success. `~bus` and `~tyr` receive the
update over Ames through their existing installs; do not copy source into their desks.

After UI edits, rebuild before syncing:

```sh
sh scripts/sync-ui-into-desk.sh
scripts/fakenet.sh sync
```

Reload an already-open browser once after a new bundle is installed. The running
UI refreshes listings/pals/config every five seconds while visible and when the
page regains focus. No Vite server is needed for the ship-served application.

## Checks

```sh
cd ui
npm ci
npm test
npx tsc --noEmit
cd ..
python3 scripts/check-sharing.py
python3 scripts/check-signed-sharing.py
```

The integration check requires `urbit`, `nc`, and all three development ships
running with `%pals` and `%omart`. It temporarily changes the three ships'
friendships and gossip settings, publishes uniquely named fixtures, and restores
the previous friendships/settings and retracts fixtures in a `finally` block.
Run it when these development ships are not being edited concurrently.
Live listing checks use a 12-second deadline; cache catch-up checks allow 30 seconds.
Do not interrupt it during cleanup. It checks:

- A watch rejected before add-back recovers in seconds; earlier and newly
  published listings arrive, in both directions.
- Removing an incoming friendship does not drop a ship still in our targets.
- Explicit HTTP and dojo retries recover a rejected subscription after a
  publisher changes tell policy, preserving gossip settings.
- A new one-hop listing stops at the direct pal; a new two-hop listing reaches
  the third ship through a chain, and its retraction follows it.
- Reconnecting to a relay does not re-originate its cached one-hop listings.
- Zero-hop publishing stays local. Withdrawals still propagate to eligible peers.

The UI tests cover add-back, dependency setup/progress/error states, install
request failures, and listing ID validation. In the ship-served browser, stopping
`%pals` hides the full Pals interface; Resume restores it and its existing state.
Fake ships cannot download from the livenet `~paldev`: the real install button
uses that source, while this fakenet continues to distribute `%pals` from `~nec`.

## Reproduced sharing failures (2026-10-08)

With the original code and default settings:

1. On `~nec`, add `~bus` as a pal. Its gossip watch is rejected because `~bus`
   has not yet added `~nec`.
2. On `~bus`, add `~nec` back.
3. Publish a listing on each ship.
4. `~bus` receives both listings; `~nec` only has its own. Its outbound gossip
   watch to `~bus` is absent. The library waits 30 minutes before retrying.

The `%near` handler now retries a desired target immediately when it adds us
back. On an agent upgrade, missing watches are reconciled too; this recovered
the already-stuck `~nec` subscription during testing. Existing watches are kept.
The vendored pals helper's `target` query also used `/mutuals` instead of
`/targets`, which could drop a still-desired subscription when leech status changed.

Two UI problems compounded this: `meet()` skipped any known ship, including
incoming-only pals, and the UI never refreshed after hydration. Incoming pals now
have an **Add back** action, and open pages refresh automatically. Both behaviors
were verified in the ship-served browser against the running fakenet.

Zero-hop publication also returned HTTP 500: the gossip library evaluated
`dec hops` before checking for zero. The zero guard now precedes rumor creation.

The earlier source-only snapshot fix has now been superseded by the signed
protocol described in [Signed sharing](docs/SHARING.md). The generic gossip library
and its randomized proxy transport have been removed.

The signed suite also checks:

- Paged catch-up of 19 publications plus withdrawals through a relay while the
  origin is disconnected; signatures remain byte-for-byte identical.
- Withdrawal arriving before publication; replays cannot revive it.
- Tampering with the signature, publisher, revision, budget, content, or withdrawal.
- Repeated publish/withdraw cycles and delayed older updates in both directions.
- Withdrawal propagation after reducing publication hops to zero.
- Two publishers using the same ID, with independent withdrawal.
- Key binding, comet identity, and both supported signature suites.
- Deterministic ordering, publication budgets and retained withdrawal relay.
- Old wrapped/unwrapped states (versions 0 and 1), migration of local publications
  and withdrawals, preservation of legacy foreign entries, and version-2 reload.
- Rejection of the unsigned legacy transport and non-pal injection.
- Unknown-key quarantine, duplicate suppression, and original expiry after retry.

The pure Hoon tests in `tests/protocol-*.hoon` build an isolated in-memory agent
when needed and never deliver its returned cards. The Python runner loads them
against the installed development desk. Ordinary fakes have fixed keys, so actual
livenet key rotation is not exercised. No livenet ships are accessed by these tests.

Tests retract their new fixtures while retaining the resulting signed tombstones.
Older diagnostic records from the original failing gossip implementation remain.
The `upgrade-signed-*` fixtures were published on all three ships before their
first signed upgrade; when present, the suite checks their migrated identities.

## Recreate from scratch

Keep an existing `.dev/fakenet` if you want to preserve development data. On a
new checkout:

```sh
scripts/fakenet.sh start
mkdir -p .dev
git clone https://github.com/Fang-/suite.git .dev/suite
git -C .dev/suite checkout b69ce154ae6ce906c2598cd46c806158b51b8a0f
```

Wait for all three dojo prompts. In `~nec`:

```hoon
|mount %base
|new-desk %pals
|mount %pals
|new-desk %omart
|mount %omart
```

Once the mounted directories exist:

```sh
scripts/install-pals-to-pier.sh .dev/suite .dev/fakenet/nec
sh scripts/install-to-pier.sh .dev/fakenet/nec
```

In `~nec`, commit each desk and wait for its commit/compilation to finish before
installing or publishing it:

```hoon
|commit %pals
|install our %pals
|commit %omart
|install our %omart
:treaty|publish %pals
:treaty|publish %omart
```

In each of `~bus` and `~tyr`, install `%pals` first, then `%omart`:

```hoon
|install ~nec %pals
|install ~nec %omart
```

Remove the upstream package's default `~paldev` target on each fake ship;
there is no live `~paldev` in this local network:

```hoon
:pals &pals-command [%part ~paldev ~]
```

In the Omart Pals page, add the other two ships on each ship (or use **Add back**
for an incoming pal). Installation source and gossip peers are independent;
installing from `~nec` does not automatically create friendships.
