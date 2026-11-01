# 33 — Prose: Archie's cases (reserve, market share)

**What to build:** `case` lines for Archie's templates: `fin_reserve`, `share_first`, `share_higher`, `share_leader`, `share_second`. Each case states the goal outright (concrete target, e.g. "25% of London's time calc"), then a real business reason in his motive: security from bills, not being pushed around by other firms' price swings ("when we're big enough we're the ones causing the swings"), spare cash to help people. Carries the true premise as tokens ({share}, {rival}, {expenses}, {float}, {weeks}, {contested}). Keep labels ≤ ~25 chars.

**Blocked by:** 31 — Ladder ownership and dual-voice

**Relevant files:**
- `docs/writing-guide.md`, `docs/CHARACTER-VOICE-GUIDE.md` (Archie), `docs/CONTENT-GUIDE.md`
- `.scratch/board-meetings/debate-rework.md` (principles + worked sample)
- `data/board.json` — templates above
- `tests/test_board_meetings.gd` (token fill)

**Status:** ready-for-agent

- [ ] Each case names the goal and why it helps; no free-floating lines
- [ ] Premise figures are tokens and true for the eligible state
- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Report flagged `PROSE-REVIEW:`
