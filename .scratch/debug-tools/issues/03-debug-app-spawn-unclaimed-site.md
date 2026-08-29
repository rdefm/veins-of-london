# 03 — Debug app: spawn an unclaimed site

**What to build:** The Debug app screen (ticket 01) gains a control to spawn a new unclaimed site directly into `state.world.sites` — the player picks the district, ore type, and terroir (hospitability) tier; the site appears immediately, discovered and unclaimed, ready to seed/claim on the Map tab exactly like any other prospected site.

**Confirmed mechanics (from 2026-08-29 grill-me session — no open design questions):**

- **Terminology:** per `CONTEXT.md`, a site is the land, a vein is what grows on it once claimed/seeded — so "spawn an unclaimed vein" (the original ask) means spawning an unclaimed **site**. Domain vocabulary in code/UI/tests should say "site", not "vein", for this action.
- **Player-chosen fields:** district (`GameData.DISTRICTS.keys()`), ore type (`GameData.ORE_TYPES.keys()`), terroir tier (poor/fair/rich/saturated, `GameData.VEIN_GROWTH["terroirYieldMult"]`'s keys) — explicitly confirmed the human wants district as a player choice too, not fixed.
- **siteCap:** this debug action bypasses each district's `siteCap` (the normal prospect-time cap/re-roll logic in `Sites.prospect()`) rather than respecting it — it's a testing tool, not a simulated prospect roll.
- **Bonuses / hasNaturalVein:** not called out by the human as player-chosen fields (only ore type + terroir + district were asked for) — default to no bonuses and `hasNaturalVein: false`, matching the existing hand-built debug fixture convention (`debug_start.gd`'s `_debug_site()` helper already does exactly this for its own hard-coded greenwich/whitechapel/camden/etc. sites). Reuse or mirror that helper rather than duplicating its shape.
- **Claimed state:** the spawned site is always unclaimed (`claimed: false`, `factionVein: null`) — that's the entire point of this action.

**Where:** the Debug app screen from ticket 01, `systems/sites.gd` (`Sites.make_site_id()`, `Sites.next_slot_index()`, and the same site-shape `debug_start.gd`'s `_debug_site()` already builds), `state.world.sites`.

**Blocked by:** 01 (needs the Debug app screen to exist).

**Status:** ready-for-agent

- [ ] Debug app screen has district, ore-type, and terroir pickers plus a spawn action.
- [ ] Spawning appends a new site to `state.world.sites` with the chosen fields, `claimed: false`, `factionVein: null`, `hasNaturalVein: false`, no bonuses, and a valid `id`/`slotIndex`/`discoveredDay`.
- [ ] Spawning ignores the target district's `siteCap` — never triggers the worst-unclaimed-site eviction/re-roll `Sites.prospect()` normally applies.
- [ ] The new site is visible and interactable (seed/claim) on the Map tab immediately, same as any other unclaimed site.
- [ ] Test coverage: spawned site has the correct fields for each chosen combination; spawning past a district's siteCap doesn't evict or re-roll anything.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
- [ ] Manual check noted for the human: from a debug start, spawn a site in a district already at its siteCap, confirm nothing else is evicted, then seed/claim the new site from the Map tab.
