# 04 — One three-marker bar for the defaults

**What to build:** In the Defaults panel, the three sliders (Make to, Keep, Sell above) become one bar with three draggable markers (Make to gold, Keep green, Sell above red), with a legend row of the three values beneath. The stock bar component gains an optional Make-to handle; in the Defaults panel it has no stock fill. Keep stays below Sell above (enforced by the system, as now), and changes commit on release. Recipe cards from ticket 02 show Make-to as a read-only tick on their bars. The slider component is deleted if nothing else uses it.

**Blocked by:** 02 — Recipe card; 03 — Defaults panel.

**Relevant files:** `scenes/phone_apps/stock_bar.gd`; `scenes/phone_apps/setting_slider.gd`; `scenes/phone_apps/bizbrief_app.gd` (`_build_master_controller`, `_build_production_recipe_row`); `systems/production_settings.gd` (`set_master_production`, `set_master_keep`); `systems/auto_sell.gd` (`set_master_sell_above`); `tests/test_stock_bar.gd`, `tests/test_production_settings.gd`, `tests/test_phone_bizbrief.gd`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] Defaults panel has one bar with three draggable markers; each commit updates the matching master setting via its system function.
- [ ] Ordering rule (Keep below Sell above) holds while dragging and on commit.
- [ ] Recipe card bars show a read-only Make-to tick.
- [ ] Stock bar tests cover the Make-to handle; slider component removed (or remaining users noted) with CODEMAP updated; all tests pass. Human on-device drag check listed.

**Scope change (agreed with user):** two markers, not three. Keep is removed everywhere (state field, `set_keep`, `lab_keep`, contract-delivery reserve, per-recipe handle); Defaults bar has Make to (gold) and Sell above (red) only. Contract delivery may draw any held stock.
