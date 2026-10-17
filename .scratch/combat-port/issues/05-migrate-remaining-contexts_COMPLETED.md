# 05 — Every remaining context migrated, plus enemy levels

**What to build:** Every combat entry runs on the new engine, using each template's archetype and the enemy-level table from §3.7b:
- vein, harder and Archie-deal muggings;
- raid, event raid, stockpile raid and faction ambush;
- vein defence, the home raid (with its opening mods: hp multiplier, enemy-first) and home-alarm defence;
- the debug launcher.

Each context's win/loss/flee consequences, `onWin` dispatch and debriefs are unchanged. Territorial and scrapper variants keep their sprites and names. After this ticket no fight starts on the old engine (the old code remains until 13).

**Blocked by:** 03, 04

**Relevant files:** `systems/combat.gd` (all `start_*`, `generate_*`, `_spawn_*`, `_home_raider_enemy`, `resolve_home_raid`, `_exit_*`); `systems/combat_prep.gd`; `systems/raiding.gd`; `systems/events.gd`; `systems/home.gd`; `systems/economy.gd`; `data/enemies.json`; `autoload/GameData.gd` (enemies validation); `tests/test_combat.gd`; `tests/test_raiding.gd`; REFERENCE §3.7b, §3.8

**Status:** ready-for-agent

- [ ] Each context launches on the new engine with the right archetype and level (one seeded test per context)
- [ ] Home raid opening mods apply under the new rules
- [ ] Existing outcome/debrief tests pass
- [ ] Enemy-level table validated at boot
