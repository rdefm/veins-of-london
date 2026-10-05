# 01 — Tier state and progress-bar experiments

**What to build:** Every craftable item has a tier 1–5 and a progress bar toward the next tier. An experiment is a random roll (modified by crafting skill); success adds progress, a full bar advances the tier. Replaces the Bench "refine" one-shot tier bump and the skill-indexed `effectPower` lookup: an item's power now comes from its tier, not crafting skill. Experiments never lower tier. New per-tier effect values come in ticket 04; this ticket proves the model end to end for existing items, reading their current power curve by tier.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/bench.gd` (`refine`, `refine_chance`, `refine_cost`, `refine_tier_target`), `systems/crafting.gd` (`effect_power`, `_active_refine_tier`, `quality_tier`), `data/recipes.json` (`effectPower`, `refineStep`), `tests/test_bench.gd`, `tests/test_crafting.gd`, `CONTEXT.md`, REFERENCE §3.5, §3.7 (inventory tier buckets), `docs/M3-CALC-DISCOVERY.md` §5/§7. Update `CODEMAP.md`. State stays pure data.

**Status:** ready-for-agent

- [ ] Per-item tier (1–5) and progress stored in pure-data state
- [ ] Experiment: roll with crafting-skill modifier; success adds progress; bar full → tier+1, progress resets; max tier stops
- [ ] Item power read from tier, not craftingSkill; tiered inventory buckets still work
- [ ] Old refine path removed, no dead code; tests cover roll, progress, tier-up, cap
- [ ] Headless tests + check_all pass
