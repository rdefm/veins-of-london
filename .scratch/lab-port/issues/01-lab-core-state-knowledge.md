# 01 — Lab system core: state, knowledge and the story grant

**What to build:** A live Lab system, promoted from the bench prototype core, that owns recipe knowledge on the real game state. A new game knows no recipes; meeting James grants the Time Pearl base procedure; events can grant recipes and hidden steps; anything that used to gate on the crafting-unlocked flag now gates on recipe knowledge. No runs yet — this is the knowledge spine every later ticket builds on. Spec: `.scratch/lab-port/spec.md` § State, § Knowledge API.

**Blocked by:** None — can start immediately

**Relevant files:**
- `systems/bench_prototype.gd` (source: `known_procedure`, `step_region`, `_insert_hinted`, `_apply_hint`, `procedure_def`)
- `data/bench_prototype.json` (source procedures for timePearl, healingSalve, healingBurst)
- new `systems/lab.gd`, new `data/lab.json`, new `tests/test_lab.gd`
- `autoload/GameState.gd` (new `lab` root; `craftingUnlocked` default), `autoload/GameData.gd` (load + validate lab data)
- `systems/events.gd` (new ops), `data/events/james_meeting.json`, `data/objectives.json`, `systems/objectives.gd`
- `CODEMAP.md`, `CONTEXT.md`
- REFERENCE.md §2 (state paths)

**Status:** ready-for-agent

- [ ] `lab` state root exists with `known`, `bestRanks`, `activeRun` (null), `performedOnce`; pure data only; step-state set can take a future "insight" value without reshaping
- [ ] Live Lab data holds the three prototype procedures; their existing hidden steps carry a rung tag (`hint1`/`hint2`/`master`)
- [ ] `grant_recipe(key)` adds a recipe at base; `grant_steps(key, idealIndices, specificity)` grants vague/exact, upgrades vague→exact in place, never downgrades
- [ ] `is_known`, `known_recipes(ore?)`, `known_procedure(key)`, `step_region` behave as in the prototype (exact steps with band, vague as region + direction, unknown hidden)
- [ ] Event ops `grant_recipe { recipe }` and `grant_recipe_steps { recipe, steps | rung, specificity }` work
- [ ] New game knows nothing; `james_meeting` grants timePearl instead of setting `craftingUnlocked`; objectives/gates that read the flag read recipe knowledge instead
- [ ] Tests: grant, upgrade, no-downgrade, new game empty, james_meeting grants timePearl, both event ops
- [ ] CODEMAP row for the Lab system + data
