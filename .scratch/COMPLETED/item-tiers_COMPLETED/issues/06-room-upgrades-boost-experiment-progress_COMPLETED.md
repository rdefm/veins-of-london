# 06 — Room upgrades boost experiment progress

**What to build:** Workshop and Library upgrades increase progress gained per successful experiment (not the success chance). Crafting skill continues to modify the success roll.

**Blocked by:** 01 — Tier state and progress-bar experiments.

**Relevant files:** `data/home.json` (rooms `workshop`, `library`, `bonus: "crafting"`), `systems/rooms.gd`, `systems/bench.gd`, `tests/test_bench.gd`. Check whether the existing crafting-chance bonus should move from craft chance to progress; ask if ambiguous.

**Status:** ready-for-agent

- [ ] Room bonuses raise progress per success; stack as today
- [ ] Bonus values data-driven; tests cover with/without rooms
