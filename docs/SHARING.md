# Signed sharing

Omart exchanges records with peers discovered through `%pals`. The persistent
publisher identity is the Urbit ship that signed the record. Relays forward the
same signed statement, without substituting themselves as publisher. There is
no random proxy or anonymous publishing mode.

## Publications and withdrawals

The signed statement contains a protocol domain, publisher, identity epoch, key
revision, listing ID, increasing revision, publication hop budget, and either the
complete listing or a withdrawal. The ship signs it with its Urbit networking
key using Zuse's `cric` interface. Keys stay inside the ship. Tests cover both
supported signature suites.

For galaxies, stars, planets and moons, receivers check the current key and
identity epoch against Jael. Comets authenticate through their public-key
fingerprint. A pal cannot publish or withdraw another ship's listing merely by
putting that ship's name in a message. A signature authenticates the publisher,
not the safety of its plugin.

Cache keys are **(publisher, listing ID)**. Two publishers can use the same ID.
Records are ordered by identity epoch, key revision, then listing revision.
Revisions increase across saves and reloads. At equal revision, withdrawal wins;
other conflicting statements from the same signer have a stable tie-breaker.
A later signed publication can intentionally restore a withdrawn listing.

An accepted newer record is stored and offered to eligible subscribers. A
withdrawal removes the visible listing and leaves a durable signed tombstone.
The tombstone propagates even through ships that never saw the publication.
Older publications cannot replace it. Tombstones do not expire, so replay
protection survives catch-up and agent reloads.

## Relay and catch-up

With `~nec → ~bus → ~tyr` and a two-hop publication:

1. `~bus` verifies and caches `~nec`'s signed listing at distance one. It can
   forward the same record to `~tyr` at distance two.
2. If `~tyr` joins later, it receives the record from `~bus`'s cache. The origin
   need not be connected at that time.
3. Any eligible path carrying `~nec`'s signed withdrawal is sufficient. Each
   receiver removes the listing, remembers the withdrawal, and relays it.
4. Replaying an old publication cannot restore it. Intentional restoration
   requires a newer statement signed by `~nec`.

Publication budgets remain 0–3 hops. Zero stays local; one reaches direct pals;
two or three permit further relaying. Cache replay never resets distance.
**The default is still one hop.** Changing the setting affects subsequent
publications; republish an existing listing to change its signed budget.
A relay uses the publisher's budget, not its own current setting. Distance is
bookkeeping by cooperating peers, not a cryptographically authenticated route.

Withdrawals have **no publication hop ceiling**: lowering the budget before a
withdrawal must not strand copies already distributed. They still follow hear/
tell policies and pal relationships. Isolated ships learn updates when an
eligible path reconnects. A deliberately uncooperative peer can keep a copy;
the protocol makes cooperating peers converge.

Subscriptions use `/omart/v2/~subscriber`. Snapshots carry up to eight records
per page: eligible cached publications and retained withdrawals. Live updates
use the same acceptance rules. On connection, every five minutes, and when
**Sync listings** is clicked, Omart reconciles subscriptions and requests catch-up.
The dojo equivalent is:

```hoon
:omart &omart-action [%retry ~]
```

With the defaults, each ship adds the other as a pal. `hear` selects subscriptions;
`tell` selects allowed subscribers. `%anybody` hearing covers incoming and outgoing
pals, not arbitrary strangers. Installing a desk does not create a pal relationship.

## Key changes

The agent subscribes to Jael for publisher key changes. Once a key stops being
current, its records stop being visible or relayable; cached ordering information
remains. The origin re-signs its own publications and withdrawals after a key
change, preserving publication budgets. Startup and the timer also check this.
Accepting a historical key with a newly claimed epoch would let a former key
holder impersonate the current ship, so that is rejected.

A valid signature whose key/epoch Jael does not yet know waits in a bounded
queue: 128 records, a 30-minute lifetime. Key notifications and periodic sync
retry it. Unknown keys never count as verified. Later catch-up can recover a
record that expired from this queue. Ordinary fakes have fixed keys; tests cover
key binding and both crypto suites, but not an actual livenet Azimuth rotation.

## Upgrade boundary

The agent migrates earlier saved states, including the generic gossip wrapper.
It signs its own existing valid listings and remembered withdrawals automatically.
Remote legacy listings stay visible with a **legacy unverified** label until an
authenticated publication or withdrawal arrives from their origin. A caching
ship never re-signs those claims or relays them as authenticated records.

All publishers and relays need this update. Old unsigned gossip is deliberately
not bridged into the signed protocol. An origin that has not upgraded can explain
a missing verified listing. After relevant ships upgrade, Sync listings requests
catch-up; owners need not manually republish valid existing listings just to sign
them. Retaining the prior one-hop budget still limits their reach.

State version 2 is unreadable by the previous agent. Keep a complete pier backup
before upgrading if rollback is required; deploying old source onto migrated
state is not a supported rollback.
