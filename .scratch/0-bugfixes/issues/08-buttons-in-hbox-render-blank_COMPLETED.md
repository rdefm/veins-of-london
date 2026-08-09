# 08 — Buttons inside a plain UI.hbox() render with no visible text

**What to build:** Discovered during human visual QA of faction-resource-economy ticket 05 — the Map tab's district panel Prospect and Travel buttons (`scenes/screens/map.gd`, `_build_district_actions()`) render as blank buttons: no label text visible at all, not even truncated/ellipsized.

Root cause (diagnosed, not yet fixed): `UI.button()` (`scenes/components/ui.gd`) sets `clip_text = true` on every button (added in bugfixes ticket 05, to stop a long dynamic label like a big cash balance forcing its container wider than the screen). In Godot 4, `clip_text = true` makes `Button.get_minimum_size()` drop the text's width contribution entirely. `_build_district_actions()` puts its buttons in a plain `UI.hbox()` (bare `HBoxContainer`, no expand flags on the buttons) — a `HBoxContainer` gives non-expand children exactly their minimum size, so with no text-driven minimum left, the button collapses to just its icon/theme padding. There's no width left for `OVERRUN_TRIM_ELLIPSIS` to ellipsize into, so the label reads as fully blank instead of clipped-with-"…" as the ticket-04 fix intended.

This is likely not unique to the district-actions row — any `UI.button()` placed inside a bare `UI.hbox()` (as opposed to `UI.hflow()`, or a row using `UI.expand_fill()` on the button) is probably affected. Worth auditing every `UI.hbox()` call site that adds buttons as direct children, not just the Map screen.

**Blocked by:** None — independent bug, can start immediately.

**Status:** ready-for-agent

- [ ] Prospect and Travel buttons in the Map tab's district panel (`scenes/screens/map.gd` `_build_district_actions()`) show their full label text (or a readable ellipsized version) at normal phone widths.
- [ ] Fix doesn't reintroduce bugfixes-04's regression (a long cost label, e.g. a big cash balance, must still not force its container wider than the screen).
- [ ] Audit other `UI.hbox()` call sites that add `UI.button()` children directly (not via `UI.hflow()` or `UI.expand_fill()`) for the same blank-text symptom, and fix any found.
- [ ] Add a test (likely in `tests/test_ui.gd` or a UI-layout test) that catches a button's rendered text collapsing to zero width when placed in a bare `HBoxContainer`, so this doesn't regress silently again.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.

Human visual QA note: on-device, confirm the Map tab's Prospect and Travel buttons (and any other buttons fixed by the audit) show readable text at normal and narrow phone widths, and that a big cash balance still doesn't blow out a button's container width.
