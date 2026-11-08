# 06 — Ore icon strip replaces the filter rows

**What to build:** The two filter chip rows (ore, and All / Following / Overridden) are replaced by one horizontally scrolling strip: "All ores" plus one chip per ore type (ore-colour dot with its symbol, then the name, min 40px high, selected chip outlined). Filtering applies within the status groups; if nothing matches the existing empty-filter text shows. The follow-mode filter and its state are removed because the groups cover it. The strip scrolls sideways inside itself and never widens the page.

**Blocked by:** 05 — Status groups and "Needs attention".

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_build_production_filters`, `_filter_button`, `_filtered_recipes`, `_set_filter_ore`, `_set_filter_follow`, `FILTER_*` constants); `data/ore_types.json` (`colour`, `symbol`); `tests/test_phone_bizbrief.gd`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] One ore strip, scrollable, with an All chip and one chip per ore type.
- [ ] Selecting an ore filters recipes inside their groups; empty result shows the empty text.
- [ ] Follow-mode filter code and constants are gone.
- [ ] Page width stays within the phone screen with the strip present (regression for the earlier BizBrief overflow).
- [ ] Tests cover the ore filter inside groups; all tests pass.
