# 18 — Drop enemy `evadeChance`

**What to build:** Enemy evade was a rule of the old per-hit attack turn; round fights (REFERENCE §3.7b) have no evade roll, and nothing reads `evadeChance` any more. It is still authored and carried everywhere: every `data/enemies.json` template (and its `_comment`), the procedural mugger (`Combat._spawn_mugger_instance()`), `Combat._enemy_capabilities_from_template()` (20% default when omitted), SaveManager's float-key lists, test fixtures and the `test_combat.gd` evade-default cases. Remove it end to end, and rewrite REFERENCE §1.10 "Enemy capability surface" so it describes `weapon` and `ability` only. `weapon` and `ability` stay (round fights read both: weapon bonus into attack range, ability for disarm, R§3.7b Table 4).

Old saves holding `evadeChance` on enemies need nothing special (an extra key in pure data is harmless; a mid-fight save keeps it until the fight ends).

**Blocked by:** None

**Relevant files:** `data/enemies.json`; `systems/combat.gd` (`_spawn_mugger_instance()`, `_enemy_capabilities_from_template()` and its comment); `autoload/SaveManager.gd` (`_ROUND_FLOAT_KEYS`, comments citing `combat.evadeChance`); `autoload/GameData.gd` (any enemies.json validation of the key); `tests/test_combat.gd` (`existing_raid_guard_templates_default_to_zero_evade_chance`, `home_raid_raider_template_defaults_to_zero_evade_chance`, `procedural_mugger_defaults_to_zero_evade_chance`, `raid_enemy_template_without_an_explicit_evadeChance_defaults_to_20_percent`, inline enemy dicts); `tests/support/fixtures.gd`; `tests/test_combat_rounds.gd` (fixture enemies); `docs/REFERENCE.md` §1.10 "Enemy capability surface", §2 `enemies` entry shape; `docs/combat-animation-vision.md` §4.2 (mentions it)

**Status:** ready-for-agent

- [ ] `grep -rn evadeChance` clean outside `.scratch/` and git history
- [ ] REFERENCE §1.10 and §2 describe the enemy shape without it
- [ ] Full suite and `scripts/check_all.sh` clean
