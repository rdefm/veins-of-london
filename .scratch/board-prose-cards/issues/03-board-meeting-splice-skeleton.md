# 03 — Board meeting on the splice skeleton (behaviour-identical)

**What to build:** the board meeting runs as a straight line of splices — minutes → opener → slot 0 → slot 1 → slot 2 → clash → vote hub → AOB — and the meeting context supplies event-card lists instead of prose strings plus goto flags. The prose still comes from today's `board.json` pools, so for the same seed and week the player sees exactly the same lines in the same order as before. Week 1 is converted the same way (it stays a separate event until 07).

First, before changing anything, capture golden played-line runs for a handful of fixed seeds/weeks/agendas (including 1-, 2- and 3-goal agendas, with and without clash and rebuttal) as a test fixture.

**Blocked by:** 02 — Splice event card

**Relevant files:**
- `systems/board_meetings.gd` — `meeting_context`, `_add_exchange`, `_add_clash`, `_result_text`, `_debate_line`
- `data/events/board_meeting.json`, `data/events/board_meeting_week1.json`
- `data/board.json` (`meeting.debate`, `templates[*].case`) — read only
- `tests/test_board_meetings.gd`, `tests/support/fixtures.gd`
- `docs/REFERENCE.md` §3.15 "Meeting event"; `CODEMAP.md`
- Spec: `.scratch/board-prose-cards/spec.md`

**Status:** ready-for-agent

- [ ] Golden runs captured before the change; the same runs match after it
- [ ] The `none`, `c<i>_last`, `c<i>_norebut` and `noclash` flags and the per-slot string tokens are gone from the context and from the event JSON
- [ ] A 1-goal agenda plays with no stray or empty cards; a 0-goal agenda goes straight to the vote
- [ ] Vote, skip, result text and AOB unchanged (existing board tests pass)
- [ ] Rewind before a meeting replays the same meeting
- [ ] REFERENCE §3.15 "Meeting event" updated
