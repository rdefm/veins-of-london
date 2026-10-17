# 07 — Live-only items, adapted

**What to build:** Panic, Pan's Rapture, Panger, Pandemonium (anger/fury statuses), Wormhole and disarm work in the new engine as actions, exactly per the §3.7b adaptation table. Their statuses tick per action or round as specified, show on the stage and strip, and affect committed enemy plans as specified (e.g. a disarmed enemy's item intents).

**Blocked by:** 01, 06

**Relevant files:** `systems/combat.gd` (`use_panic`, `use_pans_rapture`, `use_panger`, `use_pandemonium`, `_use_anger`, `_use_pan_status`, `_anger_factor`, `_enemy_fury_attack`, `_tick_anger`, `disarm_enemy`, `is_ability_locked`, `use_wormhole`); `data/recipes.json`; `scenes/components/combat_stage.gd`; `scenes/components/turn_order_strip.gd`; `tests/test_combat.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] Each item matches its §3.7b row (seeded test per item)
- [ ] Statuses are visible to the player and expire as specified
- [ ] Allies follow the existing refusal rules (allies refuse Wormhole)
