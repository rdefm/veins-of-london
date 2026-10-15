# 05 — Loadout + direct calc items: Time Pearl, Black Hole, Blast, Shield, Healing Burst

**What to build:** Calc as the ace in the hole. At setup the designer fills the player's two loadout slots with any prototype item at any tier, from a sandbox loadout rather than real inventory. In a fight, using an item costs one action, leaves the user's guard state unchanged and takes effect when its action resolves. Only the two loadout slots are usable. Time Pearl and Black Hole beat groups. Blast hurts a turtle. Shield lets you strike while staying Guarded. Healing Burst sustains. Spec: `.scratch/combat-revamp/spec.md` (User stories 6, 26, 48–53, 57, 58; Implementation Decisions: Guard-state rule, Stun and freeze removal, Prototype item effects, Damage → Shield).

**Blocked by:** 03 — Archetypes, groups, levels, crits

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/recipes.json` (`effectPower` per tier for `timePearl`, `blackHole`, `blast`, `shield`, `healingBurst`), `autoload/GameData.gd`, `tests/test_combat_prototype.gd`.

**Status:** ready-for-agent

- [ ] Config takes a player loadout of 2 × (recipe id + tier); power read from the recipe's `effectPower` at that tier
- [ ] Each slot is usable once per fight (no spamming); an item action is `unchanged` for guard state and takes effect when it resolves on the timeline
- [ ] timePearl: every living enemy loses its next `power` actions and is Open while frozen, ignoring guard and the Open condition
- [ ] blackHole: `power` damage to every living enemy ignoring guard; each loses `1 + floor(power/8)` actions
- [ ] blast: `power` damage to target ignoring guard
- [ ] shield: absorb pool of `power` drains 1:1 before HP; while > 0 the actor counts as Guarded even after Strike
- [ ] healingBurst: heals self (or a living ally once allies exist) by `power`, capped at hpMax; heal on a KO'd ally fizzles
- [ ] Tests: Time Pearl removes actions from every enemy ignoring guard; Black Hole ignores guard on all; Blast on Guarded = full power; Shield holds striker Guarded until drained; heal capped; item effect starts at its resolve point (e.g. a Pearl at index 2 doesn't stop an enemy's index-1 action); real inventory unchanged
- [ ] Screen: loadout picker (recipe + tier) in setup; items appear in the action palette with targets; used slots greyed
- [ ] Check/lint clean; suite passes; new prose flagged `PROSE-REVIEW:`
