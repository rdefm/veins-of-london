# 04 — Nav dock → TfL tile-strip

**What to build:** `scenes/components/nav_bar.gd` (the bottom
Phone/Map/HQ dock) rebuilds as a flat tile-strip in the style of TfL's own
site — a white/pale ground, thin vertical divider rules between the three
cells, a small icon over a centred label per tab, per `docs/ui-vision.md`
§5. New, simple line icons per tab (Phone/Map/HQ) — not copies of TfL's
own icon set, only the layout/visual register. Shared UI sans typeface
(not TfL's Johnston face, per §7's one-typeface-per-vector-chrome rule),
`ui_action_red` (ticket 01) for the icon/label colour instead of TfL's
brand blue (already reserved for Family 3's own future accent).

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Nav dock renders as a three-cell tile row (thin dividers, icon-over-label, centred) instead of today's chrome
- [ ] New simple icon per tab (Phone/Map/HQ) — not literal copies of TfL's icon set
- [ ] Icon/label colour uses `ui_action_red`, not blue
- [ ] Tab selection/navigation behaviour unchanged — this is a rendering swap only
- [ ] `tests/test_nav_bar.gd` updated for the new structure
