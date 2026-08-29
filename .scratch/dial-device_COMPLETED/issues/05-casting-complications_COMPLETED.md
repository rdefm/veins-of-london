# 05 — Casting a loaded Complication

**What to build:** Casting a loaded Complication in combat spends exactly
one charge (refused cleanly at `currentCharge` 0) rather than consuming the
item, computing its base effect from `Crafting.effect_power()` at the loaded
unit's tier, then applying the seated Movement archetype's amplification on
top (crafting investment and Movement investment stack, per the PRD). Spread
Movements hit every extended-target at full power with no per-target
dilution, so Spread is never strictly worse than Impact at equal charge
cost. Tier-5 Recharge Movements passively regenerate the charge pool during
combat itself — qualitatively different from "more of the same stat."
Throwing a consumable directly (today's existing path, untouched by this
whole PRD) still destroys the unit on use with no amplification — add a
regression test proving this cast/Complication path leaves that path alone.

**Blocked by:** 03 (needs `loadedComplications` to cast from), 04 (needs the
charge pool to spend from and archetype amplification data live).

**Status:** ready-for-agent

- [ ] Casting a loaded Complication spends exactly one charge and does not
      touch inventory
- [ ] Casting with `currentCharge` at 0 is refused with a reason
- [ ] Cast effect = loaded unit's `effect_power()` at its tier, amplified by
      the seated Movement's archetype
- [ ] A Spread Movement's extended-target cast hits every target at full
      power, no per-target dilution
- [ ] A tier-5 Recharge Movement passively regenerates charge during combat
- [ ] Directly throwing an unloaded consumable still destroys the unit and
      applies no amplification (regression check against the existing
      direct-use path)
