# 11 — Guard Costs screen

**What to build:** A Guard Costs BizBrief sub-view, available whether or not the pot exists.

- **Chart:** actual guard payments (hire advances + Monday bills) per day for HQ and each vein, from the guard cost history.
- **Filter:** multi-select over HQ and veins, all selected by default. Places the player no longer owns still appear while they have history in the window.
- **Header:** next Monday's guard bill (current guards × weeklyWage) and the pending shortfall, if any.
- **Opens from:**
  - the BizBrief expenses breakdown's guard wages series
  - a vein's security row (vein detail panel, vein list)
  - the guard cost on the HQ security screen

**Blocked by:** 06 — Guard shortfall: grace day and auto-drop; 10 — BizBrief expenses breakdown.

**Relevant files:**
- `scenes/phone_apps/bizbrief_app.gd`, new sub-view scene/script under `scenes/phone_apps/`
- `systems/guard_upkeep.gd` (read helpers: next bill, per-place series), `systems/phone_nav.gd`
- `scenes/components/vein_detail_panel.gd`, `scenes/screens/vein_list.gd`, `scenes/screens/hq_door.gd`
- `tests/test_guard_upkeep.gd` (read helpers)
- CODEMAP.md
- Spec §Visibility (Guard Costs screen); ui-vision.md

**Status:** ready-for-agent

- [ ] Per-place daily series come from history, bounded to `guardCostHistoryDays`
- [ ] The filter defaults to all; choosing a subset limits the chart
- [ ] The header shows next Monday's bill, and the pending shortfall when there is one
- [ ] Reachable from the breakdown guard series, vein detail panel, vein list and HQ door, including before the pot exists
- [ ] The screen only reads state; new strings flagged PROSE-REVIEW; CODEMAP updated

**Human QA on device:**
- Each entry point lands on Guard Costs.
- The filter toggles lines on and off.
- After hiring a guard, the header numbers match what you expect.
