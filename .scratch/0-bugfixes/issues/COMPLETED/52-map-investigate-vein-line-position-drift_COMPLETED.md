# 52 — Map: investigate vein/line position drift

**What to build:** Human reports that a vein's map position, or the line connecting two veins, sometimes moves — they should stay fixed once assigned. Positions are supposed to be deterministic: `MapLayout.assign_positions()` (`systems/map_layout.gd:45-63`) assigns stops to fixed slots from `data/map_layout.json`, filled in discovery order (site array append order); `build_stop_items()` (`map_layout.gd:27-38`) is meant to be order-preserving, and line routing (`systems/map_routing.gd`) is deterministic (`nearest_neighbour_order` ties broken by ascending id, `elbow_path` picks one of two fixed orientations). Since the code path looks deterministic on inspection, this needs direct investigation to find where that determinism actually breaks — likely candidates: the underlying site array's iteration/discovery order not being stable across rebuilds (e.g. a Dictionary somewhere being iterated instead of an ordered Array), or new-vein insertion shifting other veins' slot assignments rather than only claiming a fresh slot.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Root-cause found and documented: identify exactly what causes a previously-assigned stop position or line to change on a later render.
- [ ] Fix applied so a stop's assigned slot and a line's routing, once computed, remain stable across rebuilds/re-renders unless the underlying site set genuinely changes in a way that should affect them.
- [ ] New regression test: assign positions for a fixed set of sites, rebuild/re-render, assert positions and routing are byte-identical to the first assignment.
- [ ] Manual check noted for the human: play across several days/vein changes and confirm no previously-seen vein or line visibly relocates without an actual underlying change (new vein claimed, vein lost, etc.).
