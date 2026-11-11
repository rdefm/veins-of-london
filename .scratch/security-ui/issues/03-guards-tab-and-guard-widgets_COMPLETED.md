# 03 — Guards tab rows and shared guard widgets

**What to build:** a small shared set of guard widgets and the Guards tab rebuilt from them.

Widgets (reused by tickets 04–07):
- Initials avatar — guard's initials on one neutral colour picked deterministically from the guard id (not ore colours).
- Level badge — "L2", gold.
- Trait chip — label; negative traits get a "−" prefix and a dashed outline (not colour alone); mixed traits get "±".
- Status pill — post name / Reserve / Training · Nd / Injured · Nd.
- XP bar — progress within the current level.

Guards tab: filter chips All N / Posted / Reserve / Out, sort by level (highest first). Each row (≥64px): avatar, short name + level badge, XP bar with "xp/next", trait chips, status pill on the right; tapping opens guard detail. Footer line: "Reserve guards earn no XP. Post them to grow." Empty roster keeps its hint. Filter is screen-local, never in state.

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Guards artboard).

**Blocked by:** 01 — Muscle readouts for the Security UI.

**Relevant files:** `scenes/screens/security.gd` (`_build_guards`, `_build_row`, `row_text`, `post_text`), new `scenes/components/guard_widgets.gd`, `scenes/components/map_card_style.gd`, `data/muscle_traits.json` (`kind`), `data/palette.json`, `docs/ui-vision.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Widgets built in one component file; avatar colour stable per guard id
- [ ] Negative/mixed traits distinguishable without colour
- [ ] Filters and sort work; filter state not written to `GameState.state`
- [ ] Row tap opens guard detail
- [ ] CODEMAP row for the new component; check_all clean; full suite green
- [ ] PROSE-REVIEW: footer line, filter labels
- [ ] On-device checklist in the report
