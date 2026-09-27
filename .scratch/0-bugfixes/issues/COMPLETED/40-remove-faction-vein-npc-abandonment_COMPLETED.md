# 40 — Remove faction-vein NPC-abandonment mechanic

**What to build:** Faction veins currently die two independent ways that stack: `Sites.npc_abandonment_chance()` (`systems/sites.gd:362-363`, `clampf(0.02 + 0.005*age_days, 0.0, 0.08)`), rolled daily via `Sites.roll_npc_abandonment()` (`sites.gd:416-430`, wired at `systems/time_system.gd:75`, daily-tick step ⑤c) — deletes the site+vein outright on a hit — *plus* the same growth-collapse-at-zero roll player veins face (`Cultivating.collapse_vein()`, `systems/cultivating.gd:453-474`, `collapseChancePerDay` 0.15). Per the human's direction: remove the NPC-abandonment mechanic entirely. Faction veins should only be lost via the growth-collapse roll, identical to player veins.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `Sites.roll_npc_abandonment()` and its call site in `time_system.gd` daily-tick step ⑤c are removed (or the function is deleted outright if nothing else calls it).
- [ ] `Sites.npc_abandonment_chance()` removed if it has no other callers.
- [ ] Faction veins now only die via `Cultivating.collapse_vein()` — same code path already used for player veins.
- [ ] `docs/REFERENCE.md` daily-tick order (§3.1) and any NPC-abandonment mention updated to reflect removal.
- [ ] Existing tests referencing NPC abandonment updated/removed; add/update a test confirming faction veins survive absent the abandonment roll and still die via collapse-at-zero.
- [ ] Manual check noted for the human: play several in-game days and confirm faction vein counts decline only at the same pace player veins would (i.e., much slower than before).
