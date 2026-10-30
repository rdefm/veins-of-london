# 18 — Mid-raid guard bookkeeping

**What to build:** A raid can hold a fight partway through (e.g. against only the line guard) and then carry on. Winning a raid fight against N guards takes those N out of every later fight in the same raid, with no hand-authored guard-reduction step. When no guards are left, a later fight effect starts no fight. Losing a mid-raid fight still ends the raid and sends the player home, as today. A win resumes at the authored next card, as today.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`_start_raid_combat()` ~L1437 guards maths, `_reduce_raid_guards()` ~L1447, `guardsDown` in the live event context), `systems/combat.gd` (`_exit_event_raid()` ~L1769, `start_raid()`), `tests/test_raiding.gd`, REFERENCE.md §3.7b Open/Guarded round combat, §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Tests: a 1-guard fight win, then a full-guards fight, starts with one fewer; guards removed earlier plus guards beaten add up; zero guards left means no fight; a loss ends the raid; existing raid tests pass unchanged
- [ ] R§3.7b documents the carry-over
