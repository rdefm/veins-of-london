# 03 — Home raid turn cards match real turn order

**What to build:** In the home raid fight, the turn-order cards at the top still slide left/right at times. Observed: the raider always acts before the player, but the raider's card is placed after the player's, so the strip jumps when the raider goes. Diagnose and fix so the strip shows the real acting order from turn 1 and only reorders when the order genuinely changes (e.g. SPD change).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (home raid start, situational mods, `resolve_home_raid()`), `systems/combat_rounds.gd` (turn order / seeded plans), `scenes/screens/combat_rounds.gd` (builds strip entries), `scenes/components/turn_order_strip.gd` (`advance_to()` carousel), `systems/raiding.gd` (queued faction raids on the player, alarm/scripted defend fights), `tests/test_combat_rounds.gd`, `tests/test_combat.gd`; REFERENCE §3.7b.

**Status:** ready-for-agent

- [ ] Root cause identified and stated in the report (why raider acts first but card is placed after)
- [ ] Strip entry order equals actual acting order for every round of a home raid
- [ ] No card jump in home raid unless acting order actually changes
- [ ] Regression test: home raid strip order == resolved turn order
- [ ] Other fight contexts unaffected (existing tests pass)
