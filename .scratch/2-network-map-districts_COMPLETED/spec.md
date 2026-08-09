# PRD — Map Rendering: District Shapes & Multi-Faction Lines

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

`data/map_layout.json`'s district hexagons currently overlap (e.g. Camden and King's Cross anchors are 120px apart but each hexagon's own radius is ~110px), which reads as visual noise and makes `MapHitTest.district_at()` tap resolution ambiguous inside the overlap. Separately, `docs/M1.5-NETWORK-MAP.md` N2 already specifies faction-coloured lines ("each faction = its colour from factions.json"), and `MapLayout.faction_first_presence_anchor()` exists as an unused stub for it, but `map_canvas.gd`'s `_draw_lines()` only ever draws the player's line plus unconnected grey NPC stubs — faction lines were never wired up. **Chunk 1 (Faction Vein Ownership)** now gives factions real owned veins to route lines through, so this PRD finishes the rendering side N2 already promised.

## Depends on

- **Chunk 1 (Faction Vein Ownership)**: needs real faction-owned veins to exist so there's something to route/colour.

## Rules

### District shapes

- Keep the hexagon shape (no new shape language) — fix spacing so hexagons no longer overlap. Recompute hex size/anchor placement so neighbouring districts tile **edge-to-edge** (share an edge, no gap, no overlap) — a true hex-grid tiling rather than the current hand-placed-and-overlapping arrangement.
- Zone fill stays the subtle 8% colour wash N2 already specifies — this PRD fixes the overlap bug, not the fill's prominence.
- `MapHitTest.district_at()`'s tap ambiguity in overlap zones is resolved as a side effect of removing the overlap — no separate hit-test change needed.

### Visual pivot (foundational decision, detailed in Chunk 3)

- Drop the aged-paper texture background (N6's paper asset, `PAPER_COLOUR` throughout `map_canvas.gd`) in favour of a **flat, clean background** — the goal is a generic modern phone transit-app look, not a hand-drawn parchment diagram.
- This PRD locks in that pivot; the resulting palette, line styling, and stop styling are fully designed in **Chunk 3 (Map filters/visuals)**, not here.

### Multi-faction lines

- Implements N2's already-specified grammar, previously unbuilt: each faction's owned stops (from Chunk 1) get joined into that faction's own line, coloured per `factions.json`'s `colour` field, using the existing `MapLayout.faction_first_presence_anchor()` as the line's start point (same nearest-neighbour + elbow-routing logic `MapRouting` already uses for the player's line — no new routing algorithm, just applied per-faction instead of only for the player).
- The old single grey "unaffiliated NPC" stub concept goes away along with Chunk 1 retiring anonymous claims — every non-player stop now belongs to a real faction line.

### Debug verification

- `systems/debug_start.gd` is extended (same pattern as its existing 2 debug unclaimed sites) to seed a handful of example faction-owned veins spanning 2-3 factions, with multiple stops per faction so real elbow-routed multi-stop lines are exercised on a debug-started game, not just single-stop termini stubs.

## Explicitly deferred

- **Chunk 3 (Map filters/visuals)**: full palette/background/line/stop styling following the paper-texture removal.

## Open questions for the later ticket-level spec

- Exact new hex radius / anchor recompute so edge-to-edge tiling both looks like plausible London geography and keeps every district's existing `stopSlots` count (`siteCap + 2`) fitting inside the (now smaller) hexagon.
- Exact species/count of debug-start faction fixture veins (which factions, which districts, what levels/security) — left to implementation.
