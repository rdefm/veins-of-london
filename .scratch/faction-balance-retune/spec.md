# Faction balance retune

Over a 100-150 in-game-day playthrough, factions disappear from the map
and/or one faction ends up owning nearly all veins.

This exact class of problem has been fought before —
`docs/adr/0004-remove-npc-vein-abandonment.md` documents two prior
numeric-only retuning passes on faction-vein population (NPC-claim chance,
growth prune-back target) that didn't fully hold. Since then,
`systems/factions.gd`'s faction-territory-rivalry mechanism was added
(`roll_rivalry_attempts`/`rivalry_success_chance`/`resolve_rivalry_outcome`)
with an unbounded, compounding relation-grudge penalty: a losing defender's
relation toward the attacker worsens by `RIVALRY_RELATION_PENALTY` (-15)
every loss, uncapped and never decaying, which then feeds back into
`RIVALRY_RELATION_WEIGHT`'s tilt on the *next* roll against that same rival —
a rich-get-richer loop with nothing pushing back.

**Scope decision (human-confirmed):** numeric retune only, no new
floor/cap mechanisms. Keep all existing mechanic shapes (rivalry odds
formula, claim-rate formula, prune-back mechanic) as-is; only move
constants. Candidates: `RIVALRY_RELATION_PENALTY`,
`RIVALRY_RELATION_DIVISOR`/`RIVALRY_RELATION_WEIGHT`, `RIVALRY_BASE_CHANCE`,
`INDUSTRY_AGGRESSION` weights, `Sites.npc_claim_chance()`'s formula
constants, and `Sites.FACTION_PRUNE_BACK_TARGET` — implementer's call which
specific constants to move and by how much.

**Target:** no faction's vein count should ever hit (or trend toward) zero,
and no single faction should trend toward owning the large majority of
veins, over a simulated 100-150 day horizon, across multiple RNG seeds.

## Tickets

1. `01-long-horizon-simulation-harness.md` — build the observability tool
   first (tracer bullet: this alone should already demonstrate the problem
   against today's constants).
2. `02-retune-constants.md` — use the harness to iterate the retune, blocked
   by 01.

Exact numbers are drafts pending human balance sign-off, per this project's
existing convention for draft economy/balance constants.
