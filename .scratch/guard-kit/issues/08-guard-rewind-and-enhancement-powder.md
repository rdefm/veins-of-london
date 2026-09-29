# 08 — Guard Rewind + Enhancement Powder

**What to build:** Two harder guard kit rules.
- **Rewind:** when the player's hp would hit 0, after the player's own Failsafe has been tried, a guard rewinds the fight, following the ally-rewind flow. Each fire spends 1 rewind unit, and it fires on every would-be KO while the pool has one. There's no per-guard or per-fight limit.
- **Enhancement Powder:** once per guard per fight, a guard uses it on itself. The guard ally gets its own `motionTurns`/`motionPower` (`motionTurns = 2 if power >= 3 else 1`), and its extra attack entries join the round queue from the next round, as the player's do.

**Blocked by:** 07 — Guard kit pool in the fight.

**Relevant files:** `systems/combat.gd` (`_try_failsafe` ~1910, `_try_ally_rewind` ~1930, `_restore_from_snapshot`, round queue build with motion ~651–723, `use_enhancement_powder` ~1436), `tests/test_combat.gd`. Spec §Decisions. REFERENCE.md §3.7a.

**Status:** ready-for-agent

- [ ] A guard rewind fires after the player's failsafe fails and spends 1 unit per fire. Two would-be KOs with 2 rewinds give 2 saves, and none when the pool is empty.
- [ ] Enhancement Powder is used at most once per guard per fight, and that guard gets extra queue entries from the next round, with motion decrementing like the player's.
- [ ] Snapshots/restores keep per-ally motion fields consistent. New log lines flagged PROSE-REVIEW. REFERENCE §3.7a is updated.
