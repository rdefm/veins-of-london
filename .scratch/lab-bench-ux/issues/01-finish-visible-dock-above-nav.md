# 01 — Finish always visible: dock ends above nav bar

**What to build:** During a manual Lab run the docked book runs to the screen bottom, so its footer (Finish, and Done on the result page) sits under the bottom nav bar and the player can't finish a craft. The docked book's bottom edge must sit at the nav bar's top so the footer is always visible and tappable, whatever the scroll position of the steps list.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` — `_build_run`, `_build_docked_book` (footer built via `MapCardStyle.footer`)
- `scenes/components/ui.gd` — `safe_area_bottom_inset` / inset helpers
- the screen that owns the bottom nav bar (Phone / Map / HQ) — find where its height lives; reuse it, don't hardcode
- `tests/test_hq_lab_bench.gd`

**Status:** ready-for-agent

- [ ] Docked book's bottom edge = nav bar top (plus margin), not screen bottom
- [ ] Finish visible and tappable on a run with many steps (list scrolls, footer doesn't)
- [ ] Done visible on the result page after Finish
- [ ] Test asserts the docked book's rect doesn't overlap the nav bar's rect
- [ ] On-device check listed in the report
