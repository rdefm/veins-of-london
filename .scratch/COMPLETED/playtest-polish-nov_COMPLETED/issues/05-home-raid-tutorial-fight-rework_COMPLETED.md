# 05 — Home raid tutorial fight: unreadable perfect-counter raider, then pearl

**What to build:** The `prologue_home_raid_intro` fight plays with normal turn order (no raider-first). For the first few rounds the raider's move is never readable (fog forced on) and is always the perfect counter to whatever the player picked (attack/guard/dodge-type moves), so the player can't progress. After N rounds (default 3, set in event data) the pearl prompt appears. Once the player uses the Time Pearl, the fight becomes completely normal, but crit chance against the raider is 100% until the fight ends.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/prologue_home_raid_intro.json` (`start_home_raid_combat` op + `pearlLock`), `systems/combat.gd` (`start_home_raid_combat`, pearl-lock logic), `systems/combat_rounds.gd`, `autoload/GameData.gd` (`pearlLock` validation ~L2914), `data/enemies.json` (`homeRaidRaider`), `data/combat_rounds.json`, `scenes/screens/combat_rounds.gd`, `tests/test_combat.gd`, `tests/test_combat_rounds.gd`, `tests/test_prologue_chain.gd`, `tests/test_coach_marks.gd`, `docs/REFERENCE.md` (fog ~L933).

**Status:** ready-for-agent

- [ ] `pearlLock` drops `enemyBelowHp`/`raiderCounters`/`pearlCrits`; gains rounds-before-prompt and post-pearl crit lock; validation + tests updated
- [ ] Pre-pearl: raider plan always unread; raider action counters player's move (items/flee excluded from counter rule)
- [ ] Pearl prompt shown after N rounds, not before
- [ ] After pearl: normal fight, 100% crit vs raider until fight ends
- [ ] Win and loss paths still route to the debrief events
- [ ] Human checklist: turn order, fog `?`, prompt timing, crit after pearl
