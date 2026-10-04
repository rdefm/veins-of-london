# 04 — Player loadout slots in Profile

**What to build:** The player has two personal consumable slots, managed from Profile. Each slot holds one unit (recipe + tier); the same recipe may fill both. Equipping moves that exact tiered unit out of shared inventory into the slot; unequipping moves it back. Only established combat-usable consumables are equippable (Healing Salve is not); Failsafe, Rewind and Wormhole may be equipped by the player. Slots start empty on new games and migrated saves. Each slot remembers the recipe last assigned to it (for later refill); a never-assigned slot has none.

**Blocked by:** 02

**Relevant files:** new loadout system under `systems/` (or extend `systems/consumables.gd`), `autoload/GameState.gd`, `autoload/SaveManager.gd`, `scenes/phone_apps/profile_app.gd`, `tests/test_phone_profile.gd`, `data/items.json` (combat-usable allowlist; compare `systems/guard_kit.gd` allowlist), `CODEMAP.md`. Update REFERENCE §2, §3.7 with the change.

**Status:** ready-for-agent

- [ ] Equip/unequip conserves units exactly by recipe and tier
- [ ] Same recipe in both slots works; equip fails cleanly with no stock
- [ ] Non-equippable items (Healing Salve) rejected
- [ ] Slots and preferred-recipe memory survive save/load; old saves get empty slots
- [ ] Profile shows two slots with equip/unequip controls (headless scene test)
- [ ] On-device QA block in report
