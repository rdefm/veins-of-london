# 07 — Rack picker list scrolls with a thumb drag

**What to build:** In Arnie's spar prep, the practice-rack list picker can only be scrolled by grabbing the thin scrollbar at its edge. Dragging a thumb anywhere on the list should scroll it, like any phone list. A tap (no drag) still picks the item under the finger.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat_prep.gd` (practice-rack list picker), `scenes/components/map_card_style.gd` (option rows), `tests/test_combat_prep.gd`.

**Status:** ready-for-agent

- [ ] Dragging on the list's rows scrolls it (touch drag, not only the scrollbar)
- [ ] A tap without drag still selects the row; a drag never selects
- [ ] Root cause noted (e.g. row buttons eating the drag, mouse filter stop)
- [ ] Headless test where feasible: row mouse filter / scroll container setup allows drag-scroll
