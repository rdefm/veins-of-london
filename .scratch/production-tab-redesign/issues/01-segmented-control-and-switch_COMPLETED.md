# 01 — Shared segmented control and switch (prefactor)

**What to build:** Two reusable BizBrief controls: a segmented control (equal-width options, selected one has a bottom red rule, min 40px high) and an on/off switch row (label + track/knob, 44px tap target, clear on/off state). The existing Sales approach button rows (master and per-recipe) render as the segmented control. Behaviour is unchanged: same system calls, same locked/disabled look. Design reference: mockup sections "Defaults panel" and "Recipe card".

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/ui.gd`; `scenes/phone_apps/bizbrief_app.gd` (`_build_mood_row`, `_build_master_mood_row`, `_style_stats_toggle`, `MOOD_BUTTON_HEIGHT`, `MOOD_LOCKED_ALPHA`); `tests/test_phone_bizbrief.gd`; `docs/ui-vision.md`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] Segmented control and switch exist as shared components, usable by other BizBrief pages.
- [ ] Both Sales approach rows use the segmented control; selecting an option still calls the same system function and the locked (no sales staff) state still disables and dims it.
- [ ] Neither control can widen the page at phone width.
- [ ] Existing BizBrief tests pass (updated where node names change); CODEMAP updated.
