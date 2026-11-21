# 03 — Fight: outgoing damage preview ghost

**What to build:** When an action is armed (02), its target's HP bar shows the predicted damage as a lighter, glowing slice at the end of the current fill; it follows retargeting and disappears on disarm/commit. The prediction comes from a new **pure system projection** in CombatRounds: given the combat dict and a candidate player action, return each combatant's predicted HP change without mutating anything (state is pure data, so simulating on a copy with the pre-seeded rolls is fine). Damage is the **non-crit** amount unless Fate Lens combat sight (`fateCritSight`) already reveals the pre-rolled crit lands — then the crit amount shows. Open/Guarded, reflect, shields etc. follow the real resolution rules so the preview matches what actually happens.

Build the projection so 04 (incoming, all bars) and 05 (heals/status) extend it rather than replace it.

**Blocked by:** 02 — Fight: arm-then-commit action buttons

**Relevant files:**
- `systems/combat_rounds.gd` (`damage_range`, `_resolve_action`, `_deal_damage`, `_reflect_hit`, `enemy_intents`, `_plan_of`, `has_sight`)
- `systems/combat.gd`
- `scenes/components/combat_stage.gd` (slot HP bars)
- `scenes/components/turn_order_strip.gd` (existing HP ghost drain — reuse its look if it fits)
- `data/combat_visuals.json` (ghost colour/glow as data)
- REFERENCE §3.7b + Table 4, Table 5
- tests: `tests/test_combat_rounds.gd`

**Status:** ready-for-agent

- [ ] Pure projection function; test asserts state unchanged
- [ ] Projection equals real outcome when the action is committed and resolved (tests across Open/Guarded, crit hidden vs Fate sight)
- [ ] Armed damaging action shows glowing lighter slice on target bar; retarget moves it
- [ ] Crit shown only with Fate crit sight
- [ ] Ghost colour/glow read from combat_visuals.json
- [ ] CODEMAP rows updated
