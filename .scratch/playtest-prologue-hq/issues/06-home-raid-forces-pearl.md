# 06 — Home raid forces the pearl

**What to build:** The prologue home raid can't be won without using a time pearl. At a set point the fight locks so the pearl is the only playable command (same idea as the cold open's lock), so the debrief line "Used one of the pearls" is always true. The ticket covers the prologue home raid only; later home raids keep normal rules.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/home_raid_intro.json` (`start_home_raid_combat`), `systems/combat.gd` (`start_home_raid_combat`, `_home_raider_enemy`, `start_scripted_fight`), `systems/combat_rounds.gd` (scripted lock, `lockBelowHp`, allowed moves), `data/events/home_raid_debrief_win.json`, `data/events/home_raid_debrief_loss.json`, `tests/test_prologue_chain.gd`; REFERENCE.md §3.7b, §3.7 Player loadout.

**Status:** ready-for-agent

- [ ] Prologue home raid can't reach a win without a pearl being played
- [ ] The lock point is data-driven; the coach/prompt line tells the player to use the pearl
- [ ] The win debrief text stays as-is and is now always accurate
- [ ] Non-prologue home raids unchanged
- [ ] Headless test: a strike-only plan can't win; playing the pearl at the lock leads to a win
