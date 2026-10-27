# 06 — Skills restructure: Body / Mind / Soul + feats registry

**What to build:** Regroup player skills into three top-level buckets, plus a data-driven feats registry:
- **Body** = the Combat skill, renamed. Rename the state key itself (`combatSkill`/`combatXP` → Body equivalents) everywhere. **No save migration** (user decision). Sub-skills = each Move Book move (with its move level/XP).
- **Mind** = new placeholder top-level skill (level 1, XP 0, no XP source yet). Sub-skills: Sense, Crafting.
- **Soul** = new placeholder top-level skill (level 1, XP 0, no XP source yet). Sub-skill: Cultivating.
- A bucket's displayed level is its own top-level skill level, not derived from sub-skills.
- **Feats/bonuses registry:** data-driven list per skill (top-level and sub) of level → bonus/feat entries. Seed it with existing effects only: Combat/Body per-level HP/ATK/SPD/actions/crit, move Lv3/Lv5 unlocks, cultivate chance per level, craft chance per level, Sense where applicable. The schema must accept new/different feats for any skill later without code changes to the projection.
- A system-level projection (pure function over state + data) returns buckets → level/xp/next threshold → sub-skills → level/xp/next → feats (unlocked/locked at level). Ticket 07's wheel reads it.

User-facing "Combat" skill labels become "Body" (e.g. Gym card label, debug combat setup), but gym behaviour is unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:** `autoload/GameState.gd` (player defaults), `autoload/SaveManager.gd`, `autoload/GameData.gd` (data loading/validation, `COMBAT_XP_LEVELS`), `systems/combat.gd` (`skill_summary()`, level-indexed attack/speed), `systems/contacts.gd`, `systems/sparring.gd` (partners scaled off Combat Skill), `systems/progression.gd`, `systems/sense.gd`, `systems/move_levels.gd` (`MoveLevels.book()`), `systems/crafting.gd`, `scenes/modals/gym_spar_modal.gd`, `scenes/modals/combat_setup_modal.gd`, `scenes/modals/hq_gym_modal.gd`, `scenes/phone_apps/profile_app.gd` (keep compiling; wheel is 07), `scripts/sim_combat_balance_impl.gd`, `tools/lint_refs.json`, `data/combat_rounds.json` (moveLevelEffects), `data/sense.json`, tests: `test_combat.gd`, `test_combat_rounds.gd`, `test_sparring.gd`, `test_modal_layer.gd`; REFERENCE §2 player state (~line 465), §3.7a, cultChance / craft_chance formulas; `CONTEXT.md` (add Body/Mind/Soul terms), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] No `combatSkill`/`combatXP` left in code, data, tests (excluding `.scratch/` and old saves)
- [ ] Player state has Body (renamed), Mind and Soul (placeholders at 1/0)
- [ ] Bucket→sub-skill map is data, not hard-coded in screens
- [ ] Feats registry in `data/`, seeded with existing effects only; validated at load
- [ ] Projection function returns full bucket/sub-skill/feat tree; unit-tested
- [ ] Adding a new feat entry for any skill in data shows up in the projection with no code change (test)
- [ ] REFERENCE.md §2 + relevant sections, CONTEXT.md, CODEMAP.md updated
- [ ] All existing tests pass
