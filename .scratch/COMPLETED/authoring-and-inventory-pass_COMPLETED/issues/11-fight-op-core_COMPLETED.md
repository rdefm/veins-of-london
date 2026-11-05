# 11 — Fight op core

**What to build:** A new effect op starts a data-driven fight in any event. Enemies are a list of groups, each a template or faction squad plus count and level. Stat blocks stay exclusive to `start_scripted_fight`. This ticket ships kit mode `none`. Win and lose name destination cards, and fleeing uses the lose route. Entry goes through the Preparation sheet as a forced combat, and allies follow current event fight rules.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/events.gd`, `systems/combat.gd`, `systems/combat_prep.gd`, `autoload/GameData.gd`, `tests/test_scripted_fight.gd`, `tests/test_events.gd`, REFERENCE.md §3.7b Open/Guarded round combat, event action list

**Status:** ready-for-agent

- [ ] The op is in `VALID_EFFECT_OPS` and its fields are validated at load
- [ ] Fights start and resume in a non-vein event
- [ ] Template and faction squad groups both work, with count and level
- [ ] Win, lose and flee reach the right cards
- [ ] Entry is forced through Preparation
- [ ] Stat blocks are rejected on this op
- [ ] REFERENCE.md is updated
