# 11 — Combat `situational` mods

**Phase:** MVP

**What to build:** Event fight-start ops (`start_scripted_fight`, `start_raid_combat`) accept `situational: [{if: <condition>, <mod>}]`, evaluated once at fight start with the shared condition vocabulary. MVP mods: `fleeBoost` (Leg It chance), `oneAtATime` (enemies enter via the reinforcement queue), `firstStrike` (overrides `enemyFirst`), `sight: N` (rounds of sight). Active mods recorded on `state.combat` and shown at fight start. Testable with flag conditions; doesn't need observations.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (fight ops ~l.880, raid combat ~l.1277), `systems/combat.gd`, `systems/combat_prep.gd`, `systems/combat_rounds.gd` (sight, flee), `systems/raiding.gd`, `tests/test_raiding.gd`, `tests/test_combat.gd`, `tests/test_event_content_lint.gd`; REFERENCE.md combat §.

**Status:** ready-for-agent

- [ ] Each mod applies when its `if` holds and not otherwise
- [ ] `oneAtATime` routes enemies through reinforcement queue
- [ ] `firstStrike` overrides `enemyFirst`
- [ ] `sight: N` grants N rounds of sight
- [ ] Active mods on `state.combat`, shown at fight start
- [ ] Lint validates `situational` entries
- [ ] REFERENCE documents `situational`
