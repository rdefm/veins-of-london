# 04 — Wire up `james_meeting` from its storyboard proposal

**What to build:** `james_meeting` plays in the game exactly as the proposal draws it, with the live event data matching a clean promote of the proposal and every test green. Promoted from proposal4 with a 2-line prose change (kit hand-over, kit payment line). The tutorial playthrough in `test_events.gd` drives this event; confirm it still passes.

**Blocked by:** None — can start immediately.

**Relevant files:** `.scratch/writing-revamp/james-meeting-proposal4.md`, `data/events/james_meeting.json`, `tools/promote_storyboard.js`, `tests/test_event_content_lint.gd`, `tests/test_events.gd`, `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md` §3, `docs/REFERENCE.md` §3.9a. Follow the `implement-storyboard-event` skill steps 2–4.

**Status:** ready-for-agent

- [ ] No open "for Claude" comments in the proposal
- [ ] Re-promote leaves `data/events/james_meeting.json` byte-identical (or the diff is only what the draft changed)
- [ ] Every `image` path in the event exists
- [ ] `node tools/test_storyboard.js`, the content lint test and the full suite pass, with no new lint known-list entries
- [ ] Report ends with `PROSE-REVIEW: james-meeting-proposal4.md`
