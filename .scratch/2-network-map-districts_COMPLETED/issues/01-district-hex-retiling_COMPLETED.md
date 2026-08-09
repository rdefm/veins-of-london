# 01 — District hex re-tiling (edge-to-edge, no overlap)

**What to build:** Recompute `data/map_layout.json`'s district hexagons so neighbouring districts tile edge-to-edge — sharing an edge, no gap, no overlap — a true hex-grid arrangement instead of today's hand-placed-and-overlapping one (e.g. Camden and King's Cross anchors are only 120px apart while each hexagon's own radius is ~110px). Keep the hexagon shape; this is a spacing/geometry fix, not a new shape language. Every district keeps its existing `stopSlots` count (`siteCap + 2`), repositioned to fit inside its correctly sized hexagon. `MapHitTest.district_at()`'s tap ambiguity in the old overlap zones resolves as a side effect — no separate hit-test code change needed.

**Blocked by:** None — can start immediately.

**Status:** completed

- [ ] Every pair of neighbouring districts' hexagons share an edge (no gap, no overlap) in the recomputed `data/map_layout.json`, verified geometrically (e.g. a test asserting adjacent hex distance/radius relationships), not just by eyeballing.
- [ ] Each district's `stopSlots` array keeps its current count (`siteCap + 2`, unchanged from today) — only repositioned to fit the new hex size/anchor.
- [ ] Zone fill (the existing 8% colour wash) and river path rendering are visually unaffected beyond following the new hex positions — this ticket doesn't touch fill prominence or river styling.
- [ ] Tapping coordinates that used to sit in an overlap zone now resolves to exactly one district via `MapHitTest.district_at()` — covered by a test.
- [ ] Existing `map_layout`/`map_hit_test` tests still pass against the new geometry.
