# 05 — Recipe override list and filters

**What to build:** Per the approved ticket-01 direction, the recipe list under the master controller. Each row shows the recipe, stock, its effective Production/Keep/Sell-above/mood/cover, and whether it follows the master or is overridden. Editing any setting on a row overrides it; a revert-to-master tickbox (ticked = following master) returns it to master settings. Filters: ore type, and overridden vs. following master. The per-recipe "would sell today" line and the Production Log button stay.

**Blocked by:** 04 — BizBrief Production master controller.

**Relevant files:** `.scratch/production-tab/spec.md` + prototype; `scenes/phone_apps/bizbrief_app.gd` (`_build_production_recipe_row`, `_recipe_anchors`, Log toggle); `scenes/ui/stock_bar.gd`; `systems/rooms.gd` (`production_recipes`); `systems/auto_sell.gd` (`projection`); `data/recipes.json` (ingredient ore types for the filter); `data/ore_types.json`; `tests/test_phone_bizbrief.gd`; `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Rows show effective settings and follow/override state; editing a row overrides it; tickbox reverts.
- [ ] Ore-type and overridden/master filters narrow the list; empty-filter state is clear.
- [ ] Existing deep links to a recipe row (`_recipe_anchors`) and the Log still work.
- [ ] Headless tests cover override, revert, filters; all tests pass. Report on-device checks (long lists, filter controls, tickbox).
