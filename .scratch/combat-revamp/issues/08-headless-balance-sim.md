# 08 — Headless balance sim

**What to build:** A headless tool that answers "how long should a fight be?" with data. It plays N seeded fights per matchup across a grid: player level × enemy archetype/count/level × loadout, with allies optional. It drives the prototype only through `start`/`resolve_round` with two player policies. The naive policy always Strikes. The reader policy guards incoming strikes, strikes openings and feints turtles. It prints a summary table: rounds mean/p90, win %, HP left %, actions planned. Spec: `.scratch/combat-revamp/spec.md` (User stories 59–61; Implementation Decisions: Balance sim; Testing Decisions → sim acceptance).

**Blocked by:** 04 — AI allies; 06 — Tempo/sight items

**Relevant files:** new sim script under `scripts/` (+ shell wrapper alongside `scripts/run_tests.sh` if useful), `systems/combat_prototype.gd` (entry points only), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Runs headless with the project's Godot binary, to completion, no GUI
- [ ] Seeded and reproducible: same seed + grid → identical table
- [ ] Naive and reader policies implemented outside the system, using only the public entry points and read-only helpers
- [ ] Grid covers player level × enemy archetype/count/level × loadout; N per matchup configurable
- [ ] Output table: rounds mean/p90, win %, HP left %, actions planned, per matchup × policy
- [ ] Reader beats naive on win % in matched fights; result pasted into the task report
- [ ] Not part of `run_tests.sh`; CODEMAP lists the script; check/lint clean
