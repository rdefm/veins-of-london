# 18 — Debug Start seeds the real day-1 faction vein roster too

**What to build:** `DebugStart.apply()` currently hand-builds a small, deliberate demo fixture of faction-owned sites (camden/firm x2, kingscross/network x1, city/conclave x1) to exercise multi-stop elbow-routed lines on the Map tab. That fixture should stay — it's the intentional routing/claim-flow demo — but debug-started games should *also* carry the full starting faction footprint that a real "New Game" gets via `Factions.seed_day_one_veins()`. Right now a debug start under-represents faction presence on the map (e.g. only 1 Network vein, 1 Conclave vein) compared to what a real new game seeds, which makes debug play a poor stand-in for testing faction-heavy features.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `DebugStart.apply()` calls `Factions.seed_day_one_veins()` after its own hand-built `state["world"]["sites"]` list is assigned (ordering matters: `seed_day_one_veins()` appends directly to `GameState.state["world"]["sites"]`, so it must run after the debug fixture's wholesale reassignment, not before, or its output is discarded).
- [ ] Resulting debug-started game shows both the hand-built demo fixture (multi-stop firm line etc.) and the full per-faction day-one roster on the Map tab.
- [ ] `siteCap` bumps from `seed_day_one_veins()` don't conflict with or get clobbered by the debug fixture's own districts (shoreditch, greenwich, whitechapel, camden, kingscross, city all appear in both) — verify no site silently overflows its district's map slot budget.
- [ ] `test_debug_start.gd` and any other test asserting exact debug-start site/vein counts updated to account for the added roster.
