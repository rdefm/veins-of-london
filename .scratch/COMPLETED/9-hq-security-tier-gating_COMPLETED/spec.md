# Spec — HQ security: replace slot cap with tier gating

**Status:** Grilled and approved with Richard, 2026-08-11.

## Why

`docs/REFERENCE.md` §1.7 currently caps home/HQ security upgrades by an arbitrary
`maxSecuritySlots` count per home tier (bedsit=1 ... mansion=6) against 6 total
upgrades, each installable once. Richard wants that arbitrary count cap removed: if a
player can afford every upgrade, they should be able to install all of them at any
tier — but certain upgrades should be gated behind reaching a higher home tier first
(e.g. you can't hire a guard for a bedsit), which the count cap doesn't actually
express well today (a mansion happens to allow exactly 6, but a bedsit is capped at 1
regardless of which upgrade that is).

This is a deliberate canonical spec change (this project's `docs/REFERENCE.md` is the
source of truth for numbers/schema), not a bug fix — the doc gets updated alongside
the implementation.

## Decisions

- **This is HOME/HQ security only** (`docs/REFERENCE.md` §1.7, `data/home.json`).
  Per-vein security (§1.6, `data/vein_security.json`'s none/basic/warded/guarded
  tiers) is explicitly unaffected and out of scope.
- **Remove `maxSecuritySlots` as a count cap entirely.**
- **Add a `minTier` column to the security upgrades table**, same pattern the
  existing Rooms table already uses:

  | upgrade | minTier |
  |---|---|
  | lock | bedsit |
  | cameras | flat |
  | alarm | flat |
  | reinforcedDoor | townhouse |
  | ward | safehouse |
  | guard | compound |

  Exact tier assignments may be revisited during later balancing — the mechanism
  (gate by tier, not count) is the part that matters here.

## Explicitly out of scope

- Any change to per-vein security (`data/vein_security.json`).
- Final balance tuning of the `minTier` assignments beyond the table above.

## Tickets

- **01** — Replace security slot cap with tier gating.
