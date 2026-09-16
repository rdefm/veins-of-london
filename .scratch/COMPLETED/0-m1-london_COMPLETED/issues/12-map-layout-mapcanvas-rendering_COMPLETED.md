# 12 — Map layout data + MapCanvas rendering

**What to build:** `data/map_layout.json` per N3, and the `MapCanvas` `_draw()` rendering of paper → zones → river → lines → stops → badges/halos → pins → labels, including the deterministic octilinear line-routing algorithm (nearest-neighbour ordering + two-segment elbow connections), per N2/N3 of `docs/M1.5-NETWORK-MAP.md`.

**Blocked by:** 04 (renders against the interaction contract M1 already shipped).

**Status:** ready-for-agent

- [ ] `data/map_layout.json` present with all 9 districts' anchors/labelAnchors/zonePolygons/stopSlots (≥ `siteCap + 2` slots each), riverPath, homeAnchor
- [ ] `MapCanvas` renders the full draw order in N3, rebuilding from state on `state_changed`, no per-stop scenes
- [ ] Glyph grammar matches N2 exactly (vein/site/NPC-claimed stop styles, charge halo, level badge, security padlock)
- [ ] Octilinear routing: nearest-neighbour ordering is deterministic given the same state; elbow geometry matches N3's two-segment rule
- [ ] Tests: elbow geometry as pure functions, nearest-neighbour ordering determinism, stop-slot assignment (discovery-order occupancy)
- [ ] Human visual QA: from debug start, confirm every district's stops render in plausible positions with correctly coloured lines
- [ ] `godot --headless --check-only --script` clean on all touched files
