# 07 — Week 1 on the shared skeleton

**What to build:** Week 1 plays the same meeting event as every other week. An `explainer` splice, filled from the `_week1` pack only in Week 1, carries the explainer and the Owen-poach gag, then the normal debate runs. The separate Week-1 event and the `week1EventId` setting are retired. Week-1 prose is moved, not rewritten.

**Blocked by:** 04 — Prose packs: data, loader, lint

**Relevant files:**
- `data/events/board_meeting.json`, `data/events/board_meeting_week1.json` (delete)
- `data/board.json` (`meeting.week1EventId`), `data/board_prose/_week1` 
- `systems/board_meetings.gd` (`maybe_start_meeting`, context), `systems/debug_tools.gd`
- `tools/lint_refs.json`
- `tests/test_board_meetings.gd`
- `docs/REFERENCE.md` §3.15 "Meeting start"; `CODEMAP.md`
- Spec: `.scratch/board-prose-cards/spec.md`

**Status:** ready-for-agent

- [ ] Week 1 shows the explainer + Owen gag, then the debate; week 2+ shows no explainer
- [ ] Week-1 played lines match the old Week-1 event for the same seed
- [ ] No references to the Week-1 event id or `week1EventId` remain (grep clean, debug tools still work)
- [ ] REFERENCE and CODEMAP updated
