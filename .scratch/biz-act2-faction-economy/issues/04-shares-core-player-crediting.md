# 04 — Shares core + player crediting

**What to build:** London tracks who produces what. A Shares system keeps daily buckets per producer (`player`, the five faction ids, `independents`) per ore type, 14 days deep, for three tallies: ore harvested; ore used in successful crafts, split by ingredient weight; contract deliveries per buyer faction. Pure reads give ore share and crafting share per producer per ore type for the current and prior 7 days, a London overview table, and the player's supplier share per faction. The player's prunes/harvests and staff cultivator output credit the player's ore share; player and staff-producer successful crafts credit the player's crafting share (a failsafe counts toward both time and life by weight; failed crafts count nothing). Buckets roll on the daily tick before Market reprice.

Spec: §Shares, §Rollover order.

**Blocked by:** None — can start immediately.

**Relevant files:**
- New `systems/shares.gd`; `systems/cultivating.gd` (`prune`), `systems/crafting.gd` (`attempt_craft`, `recipe_ore_types`), `systems/rooms.gd` (staff block step)
- `systems/time_system.gd` (bucket roll step), `autoload/GameState.gd`, `autoload/SaveManager.gd` (empty-bucket backfill)
- `data/recipes.json` (ingredient weights)
- Tests: new `tests/test_shares.gd`, `tests/test_rooms.gd`
- REFERENCE.md §3.1, §3.4, §3.5, §6; CODEMAP new row

**Status:** ready-for-agent

- [ ] Pure reads tested: empty buckets, single producer, mixed-recipe weighting, 7/14-day window edges
- [ ] Player prune credits player ore share; staff cultivator harvest credits player ore share
- [ ] Successful player/staff craft credits crafting share by ingredient weight; failure credits nothing
- [ ] After 14 days both current and prior week report
- [ ] Buckets survive save/load; old saves backfill empty
- [ ] REFERENCE.md + CODEMAP updated
