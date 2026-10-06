# 03 — Combat: Panger and Pandemonium

**What to build:** Panger (anger): target deals +X% and takes −X% damage for 2 turns, then deals −X% and takes +X% for 2 turns, X = 25% × tier (T5 = 125%). Pandemonium (fury): same, and the target attacks its allies instead of enemies (attacks enemies if it has no allies). Single target.

**Blocked by:** 01 — Replace Pan's Prank recipes; `item-tiers` 04 — Per-tier item effects.

**Relevant files:** `systems/combat.gd` (damage calc, enemy target choice, ally lists), `systems/combat_prototype.gd`, `data/recipes.json`, REFERENCE §3.7/§3.7a, combat tests. Check damage-reduction caps and Shield interaction; ask if unclear.

**Status:** ready-for-agent

- [ ] Two-phase buff then debuff, 2+2 turns, correct multipliers per tier
- [ ] Fury redirects to allies; fallback to enemies when none
- [ ] Beats/prose PROSE-REVIEW; tests cover phases, tiers, fury fallback
