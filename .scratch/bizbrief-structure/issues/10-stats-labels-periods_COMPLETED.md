# 10 — Clarify Stats labels and time windows

Status: ready-for-agent

**What to build:** Stats tells the player what period each figure and chart covers and uses plain metric labels, while retaining the current data, visuals and Guard Costs route.

**Blocked by:** 01 — Compact BizBrief shell and Sales workstream.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/line_chart.gd`, `systems/business_stats.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §3.10 Business stats, `CODEMAP.md`.

- [ ] Revenue, expense, daily trend, expense breakdown, ore yield and item production all state the completed-day window where needed; no live-today total is mislabelled as history.
- [ ] Charts, expense-kind totals, cultivator/player toggle, items total and Guard Costs route remain correct and pot-gated.
- [ ] Empty or short history stays understandable without invented values or a new formula.
- [ ] Any new label is flagged `PROSE-REVIEW:`. Focused Godot 4.7 tests pass; human checks chart and label legibility on-device.
