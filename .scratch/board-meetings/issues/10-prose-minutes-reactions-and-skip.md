# 10 — Prose: Minutes reactions + skip line

**What to build:** the Minutes beat's prose. Per voice (Archie, James, Owen): reactions to last week's result — full success (celebrate), base-only (affectionate ribbing), miss ("next week, then" shrug) — plus a skipped-meeting variant and Archie's skip line ("You weren't there, so you're doing mine."). James correcting the minutes is available as a running gag. Token-filled from the history entry (goal label, numbers).

**Blocked by:** 05 — Monday meeting event + rollover + Act 1 hand-off

**Relevant files:**
- `docs/writing-guide.md` (required), `docs/CONTENT-GUIDE.md`, `docs/biz-meetings-vision.md`
- `data/board.json` — templates: minutes reactions, skip line
- `systems/board_meetings.gd` — minutes context tokens
- Spec: stories 6–7, 15, 20, 78

**Status:** ready-for-agent

- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Every voice × result combination has at least two variants
- [ ] No punitive tone on a miss
- [ ] Report flagged `PROSE-REVIEW:`
