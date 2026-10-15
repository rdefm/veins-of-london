# 01 — Tracer: replace old prototype with Guard/Strike 1v1

**What to build:** Remove the existing Fast/Heavy/Counter/Dodge combat prototype entirely and replace it with the thinnest end-to-end slice of the round-planning model: a 1v1 fight against a Mugger using only Guard and Strike. The designer opens the Combat Prototype card in the Debug app, picks a player Combat Skill level, starts the fight, sees the Mugger's committed intent icons on a shared timeline, fills their own action positions, previews their guard state across the round, commits, reads the beat log, and can Rewind to re-plan the same round. Spec: `.scratch/combat-revamp/spec.md` (Solution; Implementation Decisions: Replaces, Fully sandboxed, One system module, Vocabulary, Timeline order, Guard-state rule, Moves as data, Damage, Actions per round, Enemy plans, KO and outcome, Screen, Data validation).

**Blocked by:** None — can start immediately.

**Relevant files:**
- Remove/replace: `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json`, `tests/test_combat_prototype.gd`, `tests/test_combat_prototype_screen.gd`
- `autoload/GameData.gd` — table manifest entry (~l.462), `_validate_combat_prototype` + `_validate_combat_prototype_enemy` (~l.1330), comment ~l.121; existing curves `COMBAT_SPEED_BY_LEVEL`, `COMBAT_ATTACK_BONUS_BY_LEVEL` (used by `systems/combat.gd:335,796`)
- `autoload/SaveManager.gd` — `_restore_combat_prototype_int_types` (~l.1290, 1390) and comment ~l.881
- `autoload/Snapshots.gd:13` (`combatPrototype` key, cap 2 — keep)
- `autoload/GameState.gd:315` (`combatPrototype` state key — keep, reshape)
- `scenes/phone_apps/debug_app.gd`, `scenes/Main.gd` (launcher slot — reuse)
- `tests/test_gamedata.gd`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar` (old prototype fixtures/cases)
- `scripts/lint_tokens_allowlist.txt` (drop entries for deleted files)
- `CODEMAP.md` rows for system/screen/data
- Prior art: `systems/bench_prototype.gd`, `scenes/screens/bench_prototype.gd`, `tests/test_bench_prototype.gd` (sandbox pattern)
- REFERENCE §3.7/§3.7a — read-only context; live combat untouched

**Status:** ready-for-agent

- [ ] Old prototype system, screen, data, validation, SaveManager int restore, tests and allowlist entries removed; no references remain
- [ ] New prototype data table holds moves (`guard`, `strike`, each with id, name, cost, actor guard effect, target type, effect, params, condition, reserved `level`), a Mugger archetype base + weighted plan patterns, and curves for actions per round (draft `[_,2,2,3,3,3]`), crit chance and chip multiplier (draft 0.25)
- [ ] GameData validates the table at boot (well-formed moves/archetypes/patterns/curves; every pattern move id exists), with corrupt-fixture tests
- [ ] `start(config)` builds a sandboxed fight (everyone Guarded) and pre-rolls enemy plans for rounds 1 and 2; config accepts a seed and a test-only plan override
- [ ] `resolve_round(plans)` resolves by action index → speed desc → player > allies > enemies → array order; returns ordered beats + outcome (null/win/loss); rolls the following round's plans
- [ ] Strike on Open = full roll; on Guarded = `round(dmg × chip)`, min 1; Strike leaves actor Open, Guard leaves actor Guarded; guard state carries across rounds
- [ ] KO mid-round drops the KO'd combatant's remaining actions; fight ends immediately on win/loss
- [ ] Rewind restores the pre-commit state of the last committed round, including pre-rolled plans, with the plan editable again
- [ ] Tests (through `start`/`resolve_round` only): Guard→Strike vs Strike→Guard (player chip, enemy full); Strike into Guarded = chip; ending on Strike → full hit from faster enemy next round; KO drops actions; Rewind; real player hp/inventory/Dial/XP/calendar unchanged after a full fight
- [ ] Screen: Debug card launches it; setup has player level selector; timeline shows interleaved positions with enemy intent icons (type only); player fills positions from the move palette and can change any before Commit; per-combatant guard-state preview; Commit → beat log; Rewind button. Screen never mutates state
- [ ] CODEMAP updated; `scripts/check_all.sh` clean; full suite passes
- [ ] New move names / intent lines / beat lines flagged `PROSE-REVIEW:` in the report
