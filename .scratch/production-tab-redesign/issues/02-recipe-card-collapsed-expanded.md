# 02 — Recipe card: collapsed by default, with icon

**What to build:** Each Production recipe is a card that is collapsed by default and expands on tap.

Collapsed: 46px icon tile (the recipe's icon, tile tinted with its main ingredient ore's colour), a corner health pip (green at or above Keep, amber below Keep, red at 0 stock), name, "ore · make to N" sub-line, stock count, a status chip (Following muted, Custom accent), and a thin mini stock bar with a Keep tick. Recipes without their own icon show the generic placeholder.

Expanded: the stock bar with legend (Make to / Keep / Sell above), the Make-to stepper, the segmented sales approach (explainer only for the selected option), today's projection line, the cover-contracts switch, and a footer with "Custom settings" or "Following the defaults" plus a Customise / Reset to defaults link replacing the "follows master" checkbox.

Custom cards get a warm border and tinted surface; following cards are flat. Several cards may be open at once. Open state is screen-local UI state and survives refresh; it is not saved game state. The screen still never mutates game state directly.

**Blocked by:** 01 — Shared segmented control and switch.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_build_production_recipe_row`, `_build_production_control`, `_set_follows_master`, `_target_text`, `_recipe_anchors`); `scenes/components/item_icons.gd`; `scenes/phone_apps/stock_bar.gd`; `data/ore_types.json` (`colour`); `data/recipes.json` (`icon`, `ingredients`); `systems/production_settings.gd`; `docs/ui-vision.md`; `tests/test_phone_bizbrief.gd`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] Cards render collapsed by default; tapping toggles; open cards stay open across refresh.
- [ ] Collapsed card shows icon tile, name, stock, status chip, mini bar and health pip; missing icon falls back to the placeholder.
- [ ] Expanded card offers every control the old row had (Make to, Keep, Sell above, sales approach, cover contracts, follow/override) with the same system calls.
- [ ] Customise creates an override; Reset to defaults removes it; the chip and card style follow.
- [ ] Headless test covers collapsed default, expand/collapse, Customise and Reset; all tests pass. Human on-device check listed.
