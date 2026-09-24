# 04 — Harvest yield scaling by level + streak-reset invariant

**What to build:** Harvest (prune) yield scales up with the vein's earned level, on top of the existing terroir and hard-harvest bonuses. Separately, any harvest (or other condition mutation) that drops a vein's condition below 90 immediately clears its development streak — this invariant must be wired at the point where condition is mutated, not just in the harvest button handler, so it's ready for ticket 05 to build eligibility tracking on top of.

Resolved formula (from the cultivation-refining grilling session):
`levelYieldMult = 1 + 0.2 * (level - 1)` (level1=1.0x … level5=1.8x), multiplied into the existing chain alongside `terroir_yield_mult` and the hard-harvest bonus, with a single rounding at the end: `yield = round(points * yieldPerPoint * terroir_yield_mult * levelYieldMult * hardBonus)`.

Harvest depths are light=9/hard=24 (confirmed in ticket 01). Harvest result previews must show the actual resulting condition after the action — do not assume every harvest from the development zone exits it.

**Blocked by:** 01 (needs `level` field for the yield multiplier).

**Relevant files:**
- `systems/cultivating.gd` (`prune()` — add `levelYieldMult` to the yield chain; add the streak-clear-below-90 hook at the shared condition-mutation point)
- `systems/sites.gd` (terroir yield multiplier, if colocated)
- `data/vein_growth.json` (level-yield-mult constants)

**Status:** ready-for-agent

- [ ] Harvest yield includes `levelYieldMult = 1 + 0.2*(level-1)` in the existing multiplication chain, one rounding at the end
- [ ] A single shared function/hook clears the development streak whenever condition drops below 90, called from every code path that mutates condition (not duplicated per-caller)
- [ ] Harvest result preview shows the actual post-harvest condition, including cases where it stays ≥90
- [ ] Test: harvest yield scales correctly across levels 1-5, combined with existing terroir/hard-bonus multipliers
- [ ] Test: a harvest that drops condition below 90 clears the streak; a harvest that leaves it ≥90 preserves it
