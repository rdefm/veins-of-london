# 06 — Level-up resolution

**What to build:** On a night where a vein is development-eligible (ticket 05), roll for a level-up using a probability that grows with consecutive eligible days. On success: gain one level (within the terroir cap), reset condition to exactly 50, clear the streak, and end that vein's condition processing for the night — no drift is applied on top of the reset. At maximum level for its terroir tier, stop rolling entirely; condition can still exceed 90 (for harvest/raid purposes) but produces no development roll.

Resolved formula (from the cultivation-refining grilling session): `chance = min(1.0, 0.10 * (consecutive_eligible_days - 1))` — day 1 of eligibility = 0%, day 2 = 10%, day 3 = 20%, ..., capped at 100%.

**Blocked by:** 05.

**Relevant files:**
- `systems/cultivating.gd` (level-up roll + resolution, called from the same per-vein step as ticket 05's eligibility check, inside `drift_veins()`)
- `data/vein_growth.json` (level-up probability constants, if externalized)

**Status:** ready-for-agent

- [ ] Probability = `10% * (consecutive_eligible_days - 1)`, capped at 100%
- [ ] Success: level += 1 (bounded to terroir cap), condition reset to exactly 50, streak cleared, no further drift applied that night for this vein
- [ ] At terroir cap, no development roll occurs at all (not a guaranteed-fail roll — the roll is skipped)
- [ ] Test: probability schedule is exercised at day 1 (never succeeds), a middle day, the cap, and eventual 100%, using controlled RNG
- [ ] Test: successful level-up increments once, resets to 50, clears streak, and applies no additional drift that night
- [ ] Test: at terroir cap, repeated eligible nights never roll or level up
