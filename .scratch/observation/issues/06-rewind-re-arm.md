# 06 — Rewind re-arm and best-of

**Phase:** MVP

**What to build:** Rewind never makes the player forget a read, and can sharpen one. Observation results carry through `Events.rewind()` like `rolled`. Each event Rewind re-arms one extra roll (`rollCount` + 1) for every observation already read; the next Observe rolls fresh with the new seed and keeps the best tier per ore. Re-roll rows show "Rolled 31 · kept 73". XP awards on re-rolls too; tier effects only for newly reached tiers (effects themselves land in 08).

**Blocked by:** 04, 05.

**Relevant files:** `systems/events.gd` (`rewind`, ~l.788), `systems/observation.gd`, `scenes/screens/event.gd`, `tests/test_observation.gd`, `tests/test_event_screen.gd`; REFERENCE.md §3.9 Snapshots & Rewind.

**Status:** ready-for-agent

- [ ] Read results survive an event Rewind
- [ ] One Rewind = exactly one extra roll per read observation; unread observations unaffected
- [ ] Best tier per ore kept; a worse re-roll never downgrades
- [ ] Re-armed observation reported as re-armed (for the pulse in 09)
- [ ] Re-roll display rows include kept roll and whether this roll improved
- [ ] XP awarded on re-rolls
- [ ] REFERENCE Observation § covers Rewind behaviour
