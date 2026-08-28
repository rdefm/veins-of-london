# 94 — Map: vein slots still overflow / overlap

**What to build:** Two symptoms, both reported again on a build that already includes #87's fix (2026-08-26 — per-district free-list so `Sites.next_slot_index()` recycles freed slot indices instead of only ever incrementing): (1) a district's list view shows N veins belonging to a faction but the map visibly shows fewer; (2) unclaimed sites sometimes render stacked on top of each other, looking like one. #87 root-caused this to slot-buffer exhaustion from district churn and shipped a free-list fix — recurrence means either the free-list isn't being populated on every removal path, or another gap exists.

**Where:** `systems/sites.gd` (`next_slot_index`, the free-list itself), `systems/map_layout.gd` (`assign_positions`, `assign_slots`). Also touched by #93 (faction line crossing) — coordinate if worked in parallel.

**Blocked by:** None — can start immediately. Touches the same stop-positioning mechanism as #93 — coordinate if worked in parallel.

**Status:** ready-for-agent

- [ ] Re-verify #87's free-list mechanism is actually present and wired into `next_slot_index()` on current code.
- [ ] Enumerate every site/vein removal path in current code (vein sold to a faction, `Cultivating.collapse_vein()`, faction vein death via prune-back/collapse, any other path — ticket #73's progress notes are the existing map of where faction vein death happens) and check each one actually pushes its freed `slotIndex` onto the district's free list.
- [ ] Fix whichever removal path(s) were found missing the free-list push.
- [ ] Add a test that seeds enough churn in one district to exceed the old fixed slot buffer and confirms no two live stops end up clamped onto the same slot, and that faction-vein counts in the district list view match what's actually rendered on the map.
- [ ] Manual check noted for the human: play a session with heavy faction vein churn in one district (claims, deaths, sales) for a while and confirm the map's visible vein count for a faction matches the district list view, and no two unclaimed sites render on top of each other.
