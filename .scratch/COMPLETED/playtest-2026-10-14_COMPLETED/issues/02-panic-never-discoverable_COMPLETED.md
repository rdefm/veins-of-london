# 02 — Panic recipe can't be discovered or crafted

**What to build:** Player reports Panic (6 emotion, Press/compression approach) never gets discovered at the Lab bench, so it can't be learned or crafted. Diagnose why (discovery cell/approach matching, ore-type set lookup, approach availability, a gating flag, a collision with another recipe on the same emotion+compression cell, or a data/validation gap), fix it, and check the sibling emotion recipes (panger, pandemonium, pansRapture) for the same fault. The "Craft one Blast, one Shield, one Panic" objective must be completable.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/bench.gd` (cell_state, discovery lookups), `data/recipes.json` (panic entry, `discovery`), `data/approaches.json`, `systems/approaches.gd`, `data/objectives.json` (tutorial craft objective), `scenes/modals/lab_bench_*`, `docs/M3-CALC-DISCOVERY.md`, `docs/REFERENCE.md` (recipes table). Use the diagnosing-bugs skill.

**Status:** ready-for-agent

- [ ] Root cause stated in the ticket comments
- [ ] Headless test: experiment with the Panic discovery inputs can find Panic and craft it (bench + craft path)
- [ ] Same test sweep proves every recipe with a `discovery` field is reachable
- [ ] Human check: discover and craft Panic in the Lab

## Comments
Root cause NOT reproduced headless: bench discover+craft path works for every recipe with a `discovery` field (sweep test added). Real defects found + fixed: (1) save migration had no `10` arm, so v10 saves never ran the pansPrank→panic rename; (2) "inert" cells are permanent, so a cell probed before Panic/Panger/Pandemonium were authored into emotion|compression/grinding/heat stayed hidden. Load now reopens inert cells a recipe occupies. Fresh-game autosave on dev machine has empty bench, so (2) is the likely on-device cause but unconfirmed — human check needed.
