# 03 — Remove player-equippable weapons

**What to build:** The player can no longer equip weapons or crowbars. They are removed from state, data and Profile controls; existing saves lose crowbars without compensation. Player attack uses the unarmed base plus Combat Skill progression (3–7 at level 1). Authored enemy attack stats and enemy weapon bonuses are untouched. Run a combat balance check and report the result — do not add any compensating damage bonus.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/equipment.gd` (+ `tests/test_equipment.gd`), `systems/combat.gd`, `data/items.json`, `data/enemies.json` (read-only, must stay unchanged), `scenes/phone_apps/profile_app.gd`, `autoload/SaveManager.gd` (migration hook from 02 if landed, else backfill), `autoload/GameState.gd`, `CODEMAP.md`. Update REFERENCE §2, §3.7, §3.7a with the change.

**Status:** ready-for-agent

- [ ] No weapon/crowbar fields in new-game state, data or Profile
- [ ] Loading a save with a held/equipped crowbar removes it cleanly
- [ ] Player attack range at Combat Skill 1 is 3–7 in a seeded test
- [ ] Enemy weapon bonuses still apply
- [ ] Report includes a balance-check summary (representative fights) with no tuning applied
- [ ] CODEMAP and REFERENCE updated
