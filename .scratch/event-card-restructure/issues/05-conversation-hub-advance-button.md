# 05 — Conversation hubs: separate advance button

**What to build:** A conversation hub lets the player ask several questions and explore the answers before moving on, with advancing as a separate action rather than one more option. This builds on the existing hub loops (an answer's `goto` back to an earlier choice card; `reselectable`).

- An option flagged as the hub's exit renders as the footer → instead of a button row. It's still an option, so effects, checks and gating work on it.
- An optional per-hub rule sets when → is available: anytime (default), after every question has been asked, or after N questions. Until then, → is hidden.
- A one-shot question (not `reselectable`) is removed from the hub once its answer branch has played through (today's behaviour).
- A `reselectable` question stays, greyed with a tick, and can be asked again; its one-shot effects don't re-fire.
- An answer branch can be one card or several before it returns to the hub.
- The engine keeps every hub completable: if the exit rule can never be met, it logs an error and shows →.

**Blocked by:** 03 — Buttons-only choice step + footer row.

**Relevant files:** `systems/events.gd` (option listing/availability, `reselectable`, goto, `choice_record()`), `scenes/screens/event.gd` (footer →, asked-state rendering), `tests/test_events.gd`, `tests/test_event_screen.gd`, `tests/fixtures/demo_hub_questions.json`, `tests/test_event_content_lint.gd`, `docs/REFERENCE.md` §3.9a "Event choice checks" (option schema: exit flag + hub advance rule), `docs/writing-guide.md` "Hub loops", `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] The exit-flagged option shows as the footer →, not as a button
- [ ] Advance rule: anytime / all asked / after N each tested; → hidden until met
- [ ] One-shot question removed after its branch plays; `reselectable` question greyed + ticked and re-askable
- [ ] Multi-card answer branch returns to the hub
- [ ] An unmeetable advance rule still leaves the hub completable (error logged)
- [ ] Hub state (asked set, exit availability) is pure data in `state.event`; save/load and Rewind restore it
- [ ] REFERENCE schema and writing-guide "Hub loops" document the exit flag and advance rule
- [ ] Human on-device check listed: demo hub played through on device
