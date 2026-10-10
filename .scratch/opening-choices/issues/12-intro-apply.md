# 12 — Intro: apply approved choices

**What to build:** The intro event plays with its three choices and two knife-scene checks as approved in the proposal. A new player makes a decision within the first few cards; the asked-questions, wants-half, brave/injured and grabbed-calc outcomes are recorded for later events; the intro runs on Tuesday Evening and the board/labels agree.

**Blocked by:** 11 — Intro proposal (and owner approval of it); 02 — Check core; 05 — requires/goto; 06 — Event timing.

**Relevant files:** `data/events/intro.json`, `.scratch/writing-revamp/intro-proposal3.md`, `systems/events.gd`, `assets/events/intro/` (art auto-discovery), `tests/test_events.gd` or a new `tests/test_opening_intro.gd` (style of Collective Act 1 scenario tests), `tests/test_event_content_lint.gd` (if 08 landed).

**Status:** ready-for-agent

- [ ] Event JSON matches the approved proposal; existing art preserved; new cards fall back to the previous card's image.
- [ ] Scenario tests: cautious path; step-in success and fail (injury reduces current HP, flag set); bag-grab success (+2 time ore) and fail; pub "where does it come from?" recorded.
- [ ] Every path reaches the buyer setup unchanged.
- [ ] Human on-device checks listed (odds on buttons, info sheet, injury line).
