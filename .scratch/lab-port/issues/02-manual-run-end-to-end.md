# 02 — Manual run end-to-end (system)

**What to build:** A player can perform a recipe by hand against their real calc and get a real item. Begin a run on a known recipe, tap that recipe's own ore jars (spending real unstashed calc through one spend function), perform any apparatus gauge in any order and any number of times, then Finish to score the run and receive one item whose tier is the run's rank. Overshooting compress cracks the vessel; abandoning ends the run; both lose the calc and give no item. Tolerance widens with crafting skill and the player's existing bench bonuses; Prophet's Breath and Be A Lady work at the bench as they did in the prototype. Crafted items flow through Crafting so every downstream side effect fires. Spec: `.scratch/lab-port/spec.md` § Run rules, § Module structure.

**Blocked by:** 01

**Relevant files:**
- `systems/bench_prototype.gd` (source: `begin_run`, `add_ore`, `jar_amount`, `perform_step`/`perform_grind`/`perform_distil`, `score_procedure`, `match_ideal`, `rank_for_score`, `finish_procedure_run`, `band_half_width`, `lady_score_bonus`, `use_effect`)
- `systems/lab.gd`, `data/lab.json`, `tests/test_lab.gd`
- `systems/crafting.gd` (new single filing entry point: inventory, Objectives refresh, Collective, Shares, Contracts, XP), `tests/test_crafting.gd`
- `systems/perks.gd` (`craft_chance_bonus`), `systems/dial.gd` (attunement bonus), Home workshop/library bonus source (grep `workshop`)
- `systems/collective.gd`, `systems/objectives.gd`, `systems/shares.gd`, `systems/contracts.gd` (side effects currently fired from `attempt_craft`)
- REFERENCE.md §3.5

**Status:** ready-for-agent

- [ ] Only the run recipe's own jars spend calc; each tap spends that ore's per-tap amount from real orichalchum via a single spend function
- [ ] Calc cost is fixed per recipe (procedure base calc); crafting skill doesn't reduce it
- [ ] Steps record apparatus, reading and ores added since the previous step; any order, repeats allowed
- [ ] Score: weighted accuracy, in-order matching, −5 per extra step, Lady bonus, clamped 0–100; rank via data thresholds
- [ ] Finished run always yields exactly one item at tier = rank (no success roll); best rank only rises; recipe added to `performedOnce`
- [ ] Compress overshoot cracks; crack and abandon lose calc and yield nothing
- [ ] XP: finished = `xpReward`; cracked/abandoned = ⅓
- [ ] `band_half_width = baseTolerance × (1 + skillFactor × craftingSkill) × (1 + benchBonus)`; benchBonus sums Home bonus, Guild perk, and seated Movement attunement (when its ore matches an ingredient), each via a data conversion factor
- [ ] Breath reveals true bands, Lady adds score per item level, both from real active effects/items
- [ ] Manual-run hook fires once per manual run with `{recipe, score, rank, outcome}`
- [ ] No time block spent
- [ ] Crafting test: items filed via the Lab entry point fire Objectives, Collective, Shares, Contracts and XP exactly once per item
