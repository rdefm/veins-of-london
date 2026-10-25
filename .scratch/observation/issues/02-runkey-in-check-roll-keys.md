# 02 — runKey in check roll keys

**Phase:** MVP

**What to build:** Checks in repeatable events stop rolling identically on every run. A check's stable roll key gains a `runKey` (current day plus the event's context site id when present), so another night or another vein rolls fresh while a reload replays the same roll. Expose the runKey as a shared helper — the observation engine seeds from it too.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`check_roll`), `Rng.stable_unit` owner, `tests/test_events.gd`; REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] A repeatable event's check rolls differently on a different day, and differently against a different context site on the same day
- [ ] Reloading a save replays the same check roll
- [ ] Non-repeatable events' rolls unchanged (existing tests stay green)
- [ ] runKey available as a public helper for other systems
- [ ] REFERENCE §3.9a notes `runKey` for repeatable events
