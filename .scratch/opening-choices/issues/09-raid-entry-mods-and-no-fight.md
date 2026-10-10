# 09 — Home raid: opening modifiers and no-fight resolution

**What to build:** The home-raid combat request accepts opening modifiers from the event: an enemy starting-HP multiplier (ambush success → raider starts at −30% HP) and "enemy acts first" (bluff fail). A new effect resolves the home raid as a win or loss without combat, routing to the same debrief events and applying the same win/loss side effects as the combat outcome. Debrief routing stays in one place.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (`start_home_raid_combat`, `_home_raider_enemy`, `_exit_home_raid`, `_after_home_raid_combat`), `systems/combat_prep.gd` (KIND_HOME_RAID replay on Fight), `systems/events.gd` (`_apply_one`), `data/events/home_raid_intro.json`, `tests/test_home.gd` + combat tests, REFERENCE.md §3.8 (home raid loss), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Modifiers survive the combat-prep round trip and Rewind.
- [ ] HP multiplier and enemy-first verified in a started combat (tests).
- [ ] No-fight win → win debrief + homeRaidWon flags; no-fight loss → loss debrief + existing loss rule (halve held ore, owner-confirmed) via the same function as combat loss.
- [ ] Existing home-raid flow unchanged when no modifiers given.
