# 93 — Map: faction lines still cross other-faction veins

**What to build:** Faction connector lines on the Network map are still visibly crossing veins owned by other factions, reported again on a build that already includes #74's amended fix (2026-08-26 — hard no-crossing guarantee via routing fallback plus bounded position nudges as a last resort). A line should only ever touch a vein/station that belongs to that faction.

**Where:** `systems/map_routing.gd` (`elbow_path`, `_elbow_crosses_stops`, `build_line`), `systems/map_layout.gd` (`assign_positions`, `group_by_faction`), `systems/sites.gd` (`next_slot_index` — also touched by #94, coordinate if worked in parallel).

**Blocked by:** None — can start immediately. Touches the same stop-positioning mechanism as #94 — coordinate if worked in parallel, but neither blocks the other.

**Status:** ready-for-agent

- [ ] Re-verify what #74 actually shipped against its own spec (hard no-crossing guarantee; position-nudge fallback when routing alone can't avoid a crossing) — confirm the nudge-fallback path exists and is reachable on current code.
- [ ] Reproduce a case where a faction line currently crosses another faction's vein and determine why the existing guarantee didn't catch it (nudge fallback not triggering, a routing case #74 didn't cover, or a regression in the underlying routing/layout code).
- [ ] Fix so no faction's line ever visually crosses a vein it doesn't own, including whatever gap is found.
- [ ] Existing river-avoidance, other-faction-avoidance, and line-to-line spacing behaviour (#74's other criteria) remain intact.
- [ ] Add a regression test for the specific case found — evidently existing coverage doesn't catch it.
- [ ] Manual check noted for the human: play until several factions hold adjacent territory and visually confirm no line crosses a non-owned vein.
