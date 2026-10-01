# 06 — Ticker Stock Market: type filters, in-stock filter, collapsible lists

**What to build:** On the Ticker's Stock Market tab, add a row of multi-select tickboxes at the top: one per calc type (time, physics, life, fate, emotion) and one "In stock" box. Only goods matching the selected types are shown (items match if any of their recipe's ore inputs match — confirm against recipes.json); "In stock" restricts to ore/items the player currently holds. Ore and Item lists become collapsible sections. Filter/collapse state is UI-only (not in GameState).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/ticker_app.gd`, `data/recipes.json`, `data/ore_types.json`, `scenes/phone_apps/guard_costs_view.gd` (existing multi-select filter pattern), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Type tickboxes filter both lists; all ticked = everything
- [ ] "In stock" box shows only held ore/items
- [ ] Ore and Item lists collapse/expand
- [ ] Human check: filters + collapse on-device at phone width
