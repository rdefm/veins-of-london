# 02 — Pub: a finished convo returns to the 3 choices

**What to build:** In the pub event, the player reaches a card with 3 conversation choices. When one of those conversations finishes, the event goes back to the "fifteen minutes later — a Wetherspoons" intro card when it should go back to the 3-choice card. Fix it so a finished conversation returns to the choice card. If the event already hides or marks conversations that are done, keep that behaviour.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/pub.json`, `systems/events.gd` (branch/return routing), `scenes/screens/event.gd`, `tests/test_events.gd` (or the pub event's test if one exists).

**Status:** ready-for-agent

- [ ] Finishing any of the 3 conversations lands on the 3-choice card, not the intro card
- [ ] The way out of the event (after the conversations) still works
- [ ] Test drives one conversation to its end and asserts the current card is the choice card
