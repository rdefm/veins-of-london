# 23 — Reinforcement clock

**What to build:** Raising Alarm on a site with an alarm line (20) calls reinforcements (proposal §1.3). A clock counted in cards starts: each card resolved after the alarm ticks it once. At the event's clock length (default 3, the event can set it, e.g. the Shop uses 2), 2 extra guards (placeholder) join the raid's remaining guard pool for every later fight. The event can then show an arrival card (a conditional `goto` on the clock state). If a fight starts while Alarm is up and the clock hasn't fired, the 2 arrive at round 3 as a queued wave instead. Either way they arrive once per raid, never twice. They're extra bodies from the owner's crew, not the vein's guard slots: no faction cost, no guard kit. A site with no alarm line has no clock. Clock state is pure data in the event run state and survives Rewind via the snapshot.

**Blocked by:** 16 — Raid alert level; 18 — Mid-raid guard bookkeeping; 20 — Site security profile.

**Relevant files:** `systems/events.gd` (alert ops from 16, `_start_raid_combat()` ~L1430, `_reduce_raid_guards()` ~L1447, conditional `goto`), `systems/combat.gd` (`start_raid()` ~L547), `systems/combat_rounds.gd` (reinforcement queue ~L1661, ~L2000), `data/constants.json`, `tests/test_raiding.gd`, `.scratch/raid-events/raid-variants-proposal.md` §1.3, REFERENCE.md §3.7b Open/Guarded round combat, §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Clock schema and the arrival condition documented in R§3.7b / §3.12
- [ ] Tests (seeded): Alarm on an alarm-line site fires after 3 cards and adds 2 to the next fight; an event clock length of 2 fires after 2; a fight before it fires gets the 2 at round 3, and a later fight doesn't add them again; no alarm line means no clock; Rewind restores the clock
- [ ] Human on-device check: reinforcements stepping into a fight at round 3
