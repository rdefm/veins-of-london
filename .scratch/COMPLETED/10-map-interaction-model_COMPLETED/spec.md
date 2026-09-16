# Spec — Map interaction model: bubble menus + vein progress ring

**Status:** Grilled and approved with Richard, 2026-08-11.

## Why

The current Map tab has two separate, disconnected interaction patterns: tapping a
district hides the whole Network diagram and replaces it with a full-screen district
list panel; tapping a station opens a bottom sheet. Richard wants tapping either to
feel like a direct, in-place interaction with the map itself — a small popup anchored
at the tapped point, camera focused there, diagram still visible behind it — rather
than leaving the map. Separately, the vein level badge's plain number should become a
readable progress indicator toward the next level.

This depends on `0-bugfixes` ticket 11 (map tap dead until the filter drawer has been
opened once) being fixed first — these tickets build on the same tap-handling code
path and can't be meaningfully tested on top of that bug.

## Decisions

- **Vein level ring** (ticket 01): the level badge gets a thick radial fill showing
  `vein.devBar / vein_levels.json[level].devBarMax`. At a vein's max effective level
  (cap 5, or 6 with the "maxLevel" hospitability bonus) the ring shows **100% full**,
  not hidden — a maxed vein should read as "topped out," not "one harvest away."
  Companion change: once a vein is at max effective level, its Cultivate action
  becomes **disabled with a reason label** (e.g. "Vein at max level"), never hidden —
  matching the existing `disabled`-not-hidden pattern already used elsewhere (e.g.
  `hq.gd`'s recipe cards).
- **Bubble/popup component** (ticket 02): a reusable popup anchored to an arbitrary
  point on the map, diagram staying visible behind it. This is a prefactor shared by
  tickets 03 and 04 — build and unit-test it standalone before wiring it into either.
- **District bubble** (ticket 03): tapping a district camera-pans/focuses to that
  point (reusing `MapCanvas.pan_to()`) and shows a bubble with **Prospect** / **View
  Veins**. Prospect runs inline in the bubble with a procedural tween animation
  (distinct success/fail animations, matching the existing precedent in
  `docs/M1.5-NETWORK-MAP.md`'s charged-vein pulse spec — no new art assets, that's an
  explicitly deferred future follow-up). View Veins transitions into the **existing**
  full-screen district panel (reused as-is) for browsing multiple sites, since a small
  bubble can't show a full list.
- **Station bubble** (ticket 04): tapping a station camera-pans/focuses to that point
  and shows a bubble with **Cultivate** / **Harvest** / **Manage**. Cultivate and
  Harvest run inline with their own success/fail tween animations, same constraints
  as above. Manage transitions into the **existing** site sheet (already has
  tap-outside-to-close) for anything needing more room, such as adding security.

## Explicitly out of scope (this pass)

- Real art assets for any animation — procedural tween/shader effects only for v1;
  art is a deliberate future follow-up, not tracked here.
- Rebuilding the district panel or site sheet's own content — both are reused as-is,
  just reached via the new bubble instead of (district panel) replacing the diagram
  outright.

## Tickets

- **01** — Vein level progress ring.
- **02** — Anchored map bubble/popup component (prefactor).
- **03** — District bubble menu. Blocked by 02, and by `0-bugfixes` ticket 11.
- **04** — Station bubble menu. Blocked by 02, and by `0-bugfixes` ticket 11.
