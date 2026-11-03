# 01 — Live event card list accessor (prefactor)

**What to build:** every read of the live event's card list goes through one accessor. If the live event's state holds its own card list, the accessor returns that; otherwise it returns the authored event definition's cards. Players see no change. This prepares for splice (02), whose expanded card list lives in the event's state.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/events.gd` — the `_event_def()["cards"]` reads (`current_card`, card advance, goto resolution, choice checks, ~9 sites), `_event_def()`
- `systems/observation.gd` — reads `GameData.EVENTS[...]["cards"]` directly
- `systems/debug_tools.gd` — walks `event_def["cards"]`
- `tests/test_events.gd`
- Spec: `.scratch/board-prose-cards/spec.md`; REFERENCE §3.9a

**Status:** ready-for-agent

- [ ] No system reads the live event's cards except through the accessor (grep clean)
- [ ] With no stored card list, behaviour is identical: full suite passes unchanged
- [ ] A test shows that a card list stored in the event's state is what `current_card` and goto resolution use
- [ ] Any stored card list is plain data (Dictionaries/Arrays), so state stays pure and survives snapshot/Rewind
