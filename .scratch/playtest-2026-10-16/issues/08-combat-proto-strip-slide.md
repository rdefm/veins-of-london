# 08 — Combat prototype: acted card slides off the strip

**What to build:** In the combat prototype's turn-order strip, when a combatant's action resolves, their card slides off the left edge, the remaining cards shift left, and the actor's card rejoins at the end of the strip (rolling queue). Rewind playback runs it in reverse.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/turn_order_strip.gd`, `scenes/screens/combat_prototype.gd`, `systems/combat_prototype.gd` (timeline helpers), `tests/test_turn_order_strip.gd`

**Status:** ready-for-agent

- [ ] Slide-left animates per resolved action, timed with the beat
- [ ] Order after the slide matches the system's timeline
- [ ] Rewind reverses it
- [ ] Respects the pacing toggle
- [ ] On-device check listed in report
