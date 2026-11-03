# 38 — First-HQ-meeting venue beat (engine)

**What to build:** the first Monday meeting held at a new HQ venue plays a one-off beat acknowledging the move; later meetings at the same venue don't. Rewind to Monday replays it.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/board_meetings.gd` (`meeting_context`, `venue_label`, `lastProse` recording precedent)
- `data/events/board_meeting.json` (add `venueMove` splice after `minutes`)
- `autoload/GameState.gd` (`boardMeetings.venueSeen`, old saves backfill `""`, no `saveVersion` bump)
- `autoload/GameData.gd` (`_validate_board_prose`: allow slot `venue_move`)
- `data/board.json` (`meeting.venue`), `data/board_prose/_venue.json` (new pack, placeholder 1-card line)
- `tests/test_board_meetings.gd`
- REFERENCE.md §2 (state path), §3.15 (meeting event, prose packs, office ladder venue line); `CODEMAP.md`

**Status:** ready-for-agent

- [ ] `boardMeetings.venueSeen` (string, default `""`) in state; old saves backfill `""`
- [ ] `meeting_context()` returns `venueMove` cards only when `venue_label()` is not the default and differs from `venueSeen`, then records `venueSeen` (same state-pure approach as `lastProse`)
- [ ] `board_meeting` event splices `venueMove` right after the minutes card; empty splice adds nothing
- [ ] Pack lint accepts slot `venue_move`; `_venue` pack loads with placeholder prose flagged `PROSE-REVIEW:`
- [ ] Tests: fires once at `flat`; not in the workshop; not repeated; replays after Rewind
- [ ] REFERENCE.md and CODEMAP.md updated

## Comments

- Design approved in conversation: a later office tier with a new label replays the beat automatically.
