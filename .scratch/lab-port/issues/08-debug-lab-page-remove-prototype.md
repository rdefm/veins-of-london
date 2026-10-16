# 08 — Debug Lab page; remove the bench prototype

**What to build:** The Debug app gets a Lab page for playtesting the live bench: crafting-skill override (Debug-only state field, ignored when unset), grant/revoke recipes, grant hints at vague/exact, refill calc, set best rank. The sandbox prototype's system, screen, data, state key and tests are removed so there's no duplicate code path. Spec: `.scratch/lab-port/spec.md` user stories 41–42.

**Blocked by:** 05

**Relevant files:**
- `scenes/phone_apps/debug_app.gd` (`_build_bench_prototype_card`)
- `scenes/screens/bench_prototype.gd` (source: debug back page)
- `systems/bench_prototype.gd`, `data/bench_prototype.json`, `tests/test_bench_prototype.gd`, `tests/test_bench_prototype_screen.gd`
- `autoload/GameState.gd` (`benchPrototype`), `autoload/Snapshots.gd`, `autoload/SaveManager.gd`, `autoload/GameData.gd` (`BenchPrototype.match_ideal` validator → Lab)
- `systems/lab.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Debug Lab page: skill override, grant/revoke recipe, grant step vague/exact, refill calc, set best rank — all via Lab system calls
- [ ] Skill override ignored by the Lab when unset
- [ ] Prototype system, screen, data, state key, tests and all references removed (grep clean)
- [ ] CODEMAP: Debug Lab page row added, prototype rows deleted
