# 07 — Free-action spend core, wired into Cultivate

**What to build:** One block-spend function that takes a bucket (mind/soul) and returns whether the action was free, with the reason. It checks in this order:
1. Time exhausted → refused. Free actions still need time left.
2. Guild internship freebie applies → free, and Soul perks aren't consulted.
3. L5: this bucket's freebie for the current (day, block) is unused → free, and mark it used.
4. L3+: a seeded roll under 0.25 → free. The roll uses the Rng stream, so Rewind reproduces it.
5. Otherwise advance the block.

L5 still lets later actions in the same block use the L3 roll. Mind and Soul freebies are separate.

Per-block freebie state is pure data on the player: day, block, and a used flag per bucket. It resets when (day, block) changes and is backfilled on old saves.

The free-action line names the bucket, level and rule, e.g. "Free action: your Mind Level 3 perk (25% chance) saved this time block." The strings live in data.

Cultivate is the first consumer:
- it replaces its internship check + block advance;
- the result line shows in its result;
- an ambush only rolls when a block was spent, as today.

The Mind/Soul L3/L5 feat texts are added to the registry.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/time_system.gd` (`advance_time_block`, `is_time_exhausted`)
- `systems/perks.gd:349-377` (`take_free_cultivate`, internship ledger)
- `systems/cultivating.gd:242-282`
- `autoload/Rng.gd`
- `autoload/SaveManager.gd` (backfill)
- `autoload/GameState.gd` (new player field)
- `data/constants.json`
- `data/skill_feats.json`
- `tests/test_perks.gd`, time system tests
- REFERENCE.md §2 (player state), time blocks section

**Status:** ready-for-agent

- [ ] Seeded roll hit → free with the block unchanged; miss → block advanced
- [ ] L5: first action per block is free, the second rolls L3, and the freebie returns on block change
- [ ] Mind and Soul freebies are independent
- [ ] Internship is consumed first and the Soul freebie stays unused
- [ ] Exhausted time → refused
- [ ] The result carries bucket/level/rule and Cultivate shows the line
- [ ] An old-shape save loads with the freebie state present
- [ ] Rewind replays the same roll
- [ ] REFERENCE.md documents the rules and state field
- [ ] PROSE-REVIEW: free-action lines, L3/L5 feat texts
