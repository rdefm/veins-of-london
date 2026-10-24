# 01 — Wire up `cold_open` from its storyboard proposal

**What to build:** `cold_open` plays in the game exactly as the proposal draws it, with the live event data matching a clean promote of the proposal and every test green. The proposal was promoted with an `introBrave` flag set on the `stand` option, plus prose changes (hourglass line, "newbie", alley beat, Archie walk-off line). Confirm buyer's `introBrave` / `introAskedQuestions` modifiers resolve against it.

**Blocked by:** None — can start immediately.

**Relevant files:** `.scratch/writing-revamp/cold-open-proposal.md`, `data/events/cold_open.json`, `tools/promote_storyboard.js`, `tests/test_event_content_lint.gd`, `tests/test_events.gd`, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md` §3, `docs/REFERENCE.md` §3.9a. Follow the `implement-storyboard-event` skill steps 2–4.

**Status:** ready-for-agent

- [ ] No open "for Claude" comments in the proposal
- [ ] Re-promote leaves `data/events/cold_open.json` byte-identical (or the diff is only what the draft changed)
- [ ] Every `image` path in the event exists
- [ ] `node tools/test_storyboard.js`, the content lint test and the full suite pass, with no new lint known-list entries
- [ ] Report ends with `PROSE-REVIEW: cold-open-proposal.md`
