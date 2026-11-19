# 06 — Items button opens the Bag

**What to build:** an **Items** button on the recipe page bar's action row, after Auto-craft.

- **What it does:** it calls `Bag.open()` and nothing else.
- **What the player gets:** the global BagDrawer (the same drawer as the top-right bag icon) renders over the lab, so the player can use consumables (Time Pearl, Be a Lady, etc.) without leaving.
- **On close:** the same recipe and page are still showing. The lab bench must not reset its recipe-page view state on the resulting `state_changed`.

**Blocked by:** 02

**Relevant files:**
- `scenes/screens/hq_lab_bench.gd` (recipe page bar, `_refresh`)
- `systems/bag.gd` (`open`, `close`, `is_management_mode`)
- `scenes/components/bag_drawer.gd`, `scenes/Main.gd` (drawer is global; no changes expected)
- `tests/test_lab_screen.gd`, `tests/test_bag_drawer.gd` (pattern)

**Status:** ready-for-agent

- [ ] Items sets `bagDrawerOpen`; no new drawer or modal code
- [ ] After `Bag.close()` the same recipe page and page index are still shown
- [ ] Lab screen test covers both; check_all clean
