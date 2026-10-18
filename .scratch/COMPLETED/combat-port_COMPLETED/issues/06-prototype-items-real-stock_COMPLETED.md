# 06 — Prototype items with real stock

**What to build:** The eight prototype items work in live fights from the player's real loadout, at the unit's real tier: Time Pearl, Black Hole, Blast (plus its one-use Leg it boost), Shield, Enhancement Powder (extra action position this round), Prophet's Breath (sight), Be a Lady and Healing Burst (self or ally). Each takes one action and leaves guard state unchanged (Shield's override aside). Units are consumed and refill as today.

A Prophet's Breath or Be a Lady already active out of combat carries in: sight from round 1, or max rolls and 1/3 crit while it lasts. Prophet's Breath still blocks ambushes.

**Blocked by:** 03

**Relevant files:** `systems/combat.gd` (`use_slot`, `use_time_pearl`, `use_black_hole`, `use_blast`, `use_shield`, `use_enhancement_powder`, `use_prophets_breath`); `systems/combat_prototype.gd` (item effects); `systems/consumables.gd`; `systems/loadout.gd`; `systems/active_effects.gd`; `data/recipes.json`; `data/constants.json` (activeEffects); `scenes/components/combat_command_dock.gd`; `tests/test_consumables.gd`; `tests/test_active_effects.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] Each item resolves at its tier's power from real stock (seeded test per item)
- [ ] Blast raises the next Leg it chance once
- [ ] Carry-in Prophet's Breath and Be a Lady apply from round 1
- [ ] Empty or ineligible slots show a block reason
