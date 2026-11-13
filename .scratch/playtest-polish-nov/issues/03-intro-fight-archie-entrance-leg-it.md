# 03 — Intro fight: Archie enters with player, both Leg It

**What to build:** In the intro fight with Nick, Archie slides in from the left together with the player (not appearing in place after Nick attacks). At the fight's end, both Archie and the player play the Leg It animation as they run away.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/combat_stage.gd` (`play_slide_in` ~L1720, run/leg-it ~L1244-1290), `scenes/screens/combat_rounds.gd`, `data/combat_visuals.json`, `data/combat_rounds.json`, `data/events/prologue_cold_open.json`, `tests/test_scripted_fight.gd`, `tests/test_combat_command_dock.gd`.

**Status:** ready-for-agent

- [ ] Archie and player slide in simultaneously from the left; enemy from the right
- [ ] Archie visible from first frame of the entrance, not first appearing after Nick's attack
- [ ] Both play Leg It at the end
- [ ] Headless tests still pass; human visual check listed in report
