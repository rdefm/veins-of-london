# 37 — "Sell £x this week" goal (Archie, sales revenue)

**What to build:** A new Archie goal: sell £x of product this week. Add the rung (next to the market-share ladder or as its own Sales ladder — decide in-ticket and note it in the report), the goal type measuring sales revenue earned over the goal week, a premise from real state (player has sold recently), baseline-scaled tiers (base/target/stretch relative to recent weekly sales, per the vision's "scale to the player's baseline"), rewards, ToDo progress copy, and `case` prose in Archie's voice (states the £ target and why: cash means bills stop being scary, spare to help people). If the revenue source to measure or the tier scaling is unclear, STOP and ask.

**Blocked by:** 30 — Debate skeleton and data model

**Relevant files:**
- `systems/objectives.gd` (board goal types, `initial_progress`, `measure`), `systems/board_meetings.gd`
- `systems/business_stats.gd` (`record_revenue`), `systems/contracts.gd` (daily sales)
- `data/board.json` (ladders, templates, todo progress)
- `systems/todo.gd`, `tests/test_objectives.gd`, `tests/test_board_meetings.gd`
- `docs/REFERENCE.md` §3.15, `CODEMAP.md`, `docs/writing-guide.md`, `docs/CHARACTER-VOICE-GUIDE.md` (Archie)
- Spec: `.scratch/board-meetings/debate-rework.md`

**Status:** needs-info

- [ ] Goal measures real sales revenue over the goal week; baseline captured at choose time
- [ ] Rung opens only when the premise is true; met/skipped bookkeeping like other rungs
- [ ] Tiers scale to baseline; rewards in data; REFERENCE §3.15 updated
- [ ] ToDo Board row shows progress
- [ ] `case` prose follows debate-rework principles; flagged `PROSE-REVIEW:`
- [ ] Tests cover judge at each tier and a miss
