# 01 — Practice fight: sprites shrink while Arnie's coach text shows

**What to build:** In Arnie's practice fight, while the coach text is showing, the turn-order cards get huge (the "You / Your pick" card is very tall). This squashes the fight scene, so the fighter sprites shrink. Once a move is picked, everything goes back to normal size. Fighter sprites and turn-order cards should stay at their normal size the whole time the coach text is up. Screenshot: `.scratch/playtest-prologue-hq-2/practice-fight-tiny-sprites.png`.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat_rounds.gd` (coach text / readouts layout), `scenes/components/turn_order_strip.gd`, `scenes/components/combat_transcript.gd`, `data/events/gym.json` (glovesOn `start_scripted_fight`, `coach`), `tests/test_gym_event.gd`.

**Status:** ready-for-agent

- [ ] Turn-order cards keep their normal size while coach text is shown
- [ ] Fighter sprites keep the same scale before and after a move is picked
- [ ] Root cause stated in the report
- [ ] Headless test where feasible: the strip/card sizes match with coach text shown and hidden
