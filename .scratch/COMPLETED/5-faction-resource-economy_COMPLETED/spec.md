# PRD — Faction Resource Economy

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

**Chunk 1 (Faction Vein Ownership)** established that faction vein security is resource-gated ("a resource-strapped faction can't afford to secure everything at max tier") but explicitly deferred designing the resource stat itself. This PRD designs it — scoped tightly to what Chunk 1 actually needs, with the larger staff-allocation and barometer-influence ideas captured as documented future direction rather than built now (same pattern as Chunk 1's cultivator-staffing note).

## Depends on / feeds

- **Chunk 1 (Faction Vein Ownership)**: security-tier rolls consult this resource balance.
- **Chunk 1c (Faction Territory Rivalry)**: likely to consult the same balance for contest odds (designed there, not here).

## Rules (near-term scope)

### Resources are a real ledger, not a derived stat

- Each faction accumulates resources as a currency balance over time (income in, spend out) — not recalculated fresh from current holdings each tick. A faction that's earned and then lost veins can still be temporarily flush or broke depending on its balance, not just its current territory snapshot.

### Income

- **Vein-derived income**: each faction periodically converts its held veins' ore into resources — the same shape as the player's own cultivate-then-sell loop, just automated.
- **Base/passive income**: each faction also has some fixed passive income reflecting its `industries` (from `factions.json`) — e.g. the Conclave's institutional influence or the Guild's crafting contracts generate something even independent of how many veins they currently hold.
- Together, these are what seed the wealth differences implied by each faction's existing flavour text (Guild/Conclave read richer; Collective reads scrappier, per their `factions.json` descriptions) — differentiated further by starting baselines, below.

### Spend (near-term scope: security only)

- The only spend category this PRD defines: upgrading a held vein's security tier, gated by whether the faction can afford that tier's `cost` (already present in `vein_security.json` — no new cost table needed). This is what Chunk 1's security roll actually consults.
- No other spend category is built in this pass (see Future direction, below).

### Starting baselines

- Factions start with **different baseline resource levels**, seeded from their existing flavour text — Conclave and Guild start richer, Collective starts scrappier, etc. — so factions read as differentiated from the start of a playthrough rather than converging to look the same before income differences compound.

### Visibility

- The resource balance is **never shown directly to the player** (no wealth number/indicator on the Factions screen). The player only infers it indirectly — by observing how much territory a faction holds and what security tiers their veins tend to carry, same as reading wealth in the real world. No change to the existing Factions screen (`systems/factions.gd`) for this pass.

## Future direction (documented, not designed now)

Two bigger ideas were raised and deliberately **not** built in this pass — noted here so they aren't lost, to be designed as their own PRDs when picked up:

- **Staff allocation**: factions spend resources on staff with distinct roles — cultivators (vein growth, ties into Chunk 1's already-deferred cultivator-staffing model: 1 cultivator per vein at normal rate, spread across 2 veins costs -25%), armsmen (combat/security strength, presumably feeding raid-defense difficulty in the raiding PRD), and prospectors (finding/claiming new veins, presumably an alternative or supplement to Chunk 1's daily-tick claim roll). Resource level would gate how much staff a faction can field.
- **Barometer influence**: factions spending resources to actively push the global economic/social/political barometer (`state.barometer`) in directions that favour them — turning the barometer from a background/event-driven system into something factions actively compete over.

## Open questions for the later ticket-level spec

- Exact income formulas (vein-income rate, per-faction base-income values) and how they map to the starting-baseline differentiation.
- Exact security-tier-affordability check (does a faction always upgrade when it can afford to, or is there some restraint/priority logic even in the near-term scope).
- Whether/how this resource balance interacts with Chunk 1's abandonment rule (does a totally broke faction abandon veins faster, or is abandonment purely age-based as Chunk 1 specifies) — not addressed here, worth resolving before implementation.
