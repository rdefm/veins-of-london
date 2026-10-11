# 02 — Engine: options are one-shot unless `reselectable`

**What to build:** on a hub re-entered via a loop, an option the player already picked is hidden on later visits unless it carries `reselectable: true`. Absent field = one-shot (no change for non-loop events, since cards are visited once). A picked one-shot option's effects never re-fire. The hub must always keep at least one visible option that is not a back-edge (forward exit); if every forward-exit option were hidden, the engine keeps the event completable (logs an error, shows the exit).

**Blocked by:** 01 — Engine: backward goto to a choice card.

**Relevant files:** `systems/events.gd` (option listing/availability), event screen under `screens/` (render only — reads the filtered option list, no state mutation), REFERENCE.md event/option schema § (add `reselectable`), `tests/test_events.gd`, `CODEMAP.md`. State must stay pure data (record picked option ids per hub visit-set in `state.event`).

**Status:** ready-for-agent

- [ ] Picked option hidden on hub return; `reselectable: true` option still shown
- [ ] One-shot option effects fire once only
- [ ] Per-playthrough: resets when the event runs again
- [ ] Hub with no remaining forward exit cannot soft-lock
- [ ] Picked-option record is plain data and survives save/Rewind
- [ ] Tests for both option kinds across multiple loops
