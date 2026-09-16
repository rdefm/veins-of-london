# Spec — Faction day-1 starting veins

**Status:** Grilled and approved with Richard, 2026-08-11.

## Why

Today, rival factions only ever acquire sites/veins via the daily NPC-claim tick
(`docs/M1-LONDON.md` §D2, "NPC site-claiming") — a slow probabilistic climb starting
from zero. On a fresh game this makes the other five factions feel absent for a long
stretch. Richard wants new games to start with each faction already holding a
meaningful roster of veins, so the Network map and faction presence feel populated
from day one.

## Decisions

- **Day-1 initialization only.** The ongoing daily NPC-claim tick rate/weights are
  **unchanged** — this is purely an addition to new-game setup, using the same
  `factionVein`/site mechanism the daily tick already uses.
- **Rosters** (exact):
  - Collective: 8 veins, levels 1–3, split evenly (4/4) across its two home districts
    (Shoreditch + Whitechapel, per `factionPresence` in `docs/M1-LONDON.md` §D1).
  - Firm: 4 veins, levels 2–3, split evenly (2/2) across its two home districts
    (Camden + Battersea).
  - Guild: 5 veins at levels 2–3, plus 2 veins at level 4 (7 total), all in its one
    home district (Greenwich).
  - Network: 4 veins, levels 3–4, all in King's Cross (its only viable district for
    veins — Soho has `siteCap: 0` and explicitly allows no veins/prospecting).
  - Conclave: 4 veins at levels 2–4, plus 3 veins at level 5 (7 total), all in its one
    home district (City).
- **Level rolls are fixed constants, not re-rolled per game.** Where a range was given
  without an exact split (Collective 1–3, Firm 2–3, Network 3–4), each vein's level
  was rolled once, randomly/uniformly within that range, and the resulting specific
  values are hardcoded — every new game gets the same level distribution. Guild's and
  Conclave's splits were already exact, not rolled.
- **Everything else stays procedural.** District assignment beyond the even split,
  location/street name, oreType, security tier, and bonuses are generated fresh each
  new game using the existing site/vein generation logic — the same as a normal NPC
  claim would produce. Nothing about these veins looks identical run to run except
  their levels.
- **`siteCap` is bumped, not spent.** Every district that receives starting faction
  veins gets its `siteCap` (`docs/M1-LONDON.md` §D1 / `data/districts.json`)
  increased by the exact count of starting faction veins placed there, so normal
  player prospecting capacity in that district is unaffected by this seeding.
  Exact `siteCap` numbers are expected to move again during later balancing —
  implement the "base + placed count" mechanism correctly; don't over-index on the
  precise numbers landing here.

## Explicitly out of scope

- Changing the ongoing daily NPC-claim probability/weighting curve.
- Any change to per-vein security tiers (`data/vein_security.json`) beyond however
  the existing NPC-claim security-tier roll already works.
- Rebalancing `siteCap` numbers beyond the mechanical "base + placed count" bump —
  final tuning is a separate future pass.

## Tickets

- **01** — Day-1 faction vein rosters.
