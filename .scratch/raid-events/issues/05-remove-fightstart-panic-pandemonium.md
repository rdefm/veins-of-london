# 05 — `remove` + `fightStart`: Panic and Pandemonium

**What to build:** Raid approaches can shape the fight before it starts.
- The combat entry reads a start-of-fight payload from the chosen approach (pure data in state), so combat has no per-event special-casing.
- `remove`: N guards leave before the fight (reuse the existing guards-down count). If no guards remain, the fight is skipped.
- `fightStart` reuses existing combat statuses: enemies start with `panicActions` (afraid), `raptureActions` or `angerActions` (infighting), plus `enemyStartsHurt` (HP loss). `enemyStartsHurt` is set per approach, never global, and never takes an enemy below 1 HP.
- **Panic:** guards flee (`remove`) or start afraid (`fightStart` panic) — per approach.
- **Pandemonium:** guards turn on each other before the fight (`fightStart` anger + start hurt, may also `remove`).
- The fight view shows the start state via the existing status badges plus a fight-log line per effect.

Numbers are placeholders. Placeholder prose; real prose lands in ticket 07.

**Blocked by:** 03 — Item effect engine.

**Relevant files:** `systems/combat.gd` (`start_raid()` ~L542, `_start_combat()`, `situational_active()`), `systems/combat_rounds.gd` (combatant init ~L585, panic/rapture/anger statuses ~L285-366, ~L2576), `systems/events.gd` (`_start_raid_combat` ~L1330, `_reduce_raid_guards`), `data/events/vein_raid.json`, `tests/test_raiding.gd`, `docs/REFERENCE.md` §3.7b.

**Status:** ready-for-agent

- [ ] Fight-start payload schema documented in R§3.7b
- [ ] Tests: remove reduces guard count; all removed skips the fight; panic/anger statuses set at start; start-hurt floors at 1 HP; payload absent = unchanged fight
- [ ] Panic and Pandemonium approaches wired in `vein_raid`
- [ ] Fight-log lines flagged `PROSE-REVIEW:`
- [ ] Human on-device check: enemies show panic/anger badges and reduced HP at round 1; fewer guards after Panic flee
