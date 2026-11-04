# 03 — Collapsible seller recipes

**What to build:** Buying from Wren or James shows one collapsed row per recipe, with icon, name and effect sentence. Tapping expands its rungs and tapping again collapses them. Known rungs show a tick badge instead of a buy button. Locked rungs keep their reason. An ore filter at the top offers All plus only the ores that seller teaches, using the Lab recipe book's ore grouping. Expanded rows and the filter are local view state.

**Blocked by:** 02

**Relevant files:** `scenes/modals/sell_menu_view.gd`, `scenes/screens/hq_lab_bench.gd` (ore grouping), `systems/recipe_knowledge.gd`, `data/recipe_knowledge.json`, `tests/test_recipe_knowledge.gd`, `tests/test_recipe_seller_trade.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] One row per recipe with name, icon and `effectText`
- [ ] Rows expand and collapse on tap
- [ ] Known rungs show a tick badge and no buy button
- [ ] Locked rungs show their current reason
- [ ] James's filter offers only time and life; no filter gives an empty list
- [ ] Basket, review and pay flow is unchanged, including buying several rungs at once
- [ ] No expansion or filter state enters game state
- [ ] Pure tests cover recipe rows and seller filters
- [ ] Human QA block lists collapse feel and filter layout
