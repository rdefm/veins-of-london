# 30 — Debate skeleton and data model (placeholder prose)

**What to build:** The Monday meeting plays as a debate instead of an agenda dump: minutes, an opener, then per offered goal a case (pitcher), a response (another voice: back / challenge / wobble) and, after a challenge, an optional rebuttal; an optional clash between the two most-opposed voices; then a vote card where option labels are plain goal names with the pitcher, and tiers/rewards sit on the vote prompt; then a chosen line from the pitcher and a concede line from one other voice; then any other business. Works with 1–3 goals (empty slots skipped via ticket 29), is seeded (week + rollSeed) so Rewind shows the same scene, and the skip option stays on the vote card.

Data: each template's `pitch` + `why` merge into one `case` list (mechanical merge of existing lines is fine as placeholder; real rewrites are tickets 33–35). New `meeting.debate` block per the spec (opener, response, rebuttal, clash, votePrompt, chosen, concede). Remove `agendaCard`, `agendaSeparator`; move tier/reward formats to the vote prompt. Seed the debate block with short **placeholder** lines so every path is exercisable; ticket 32 writes the real prose.

Selection rules: response stance and responder are seeded; Owen defaults to `wobble` toward veins when not pitching; rebuttal only after `challenge`; clash ~50%, keyed by voice pair, only when two offered pitchers differ.

**Blocked by:** 29 — `context_flag` condition

**Relevant files:**
- `systems/board_meetings.gd` (`meeting_context`, `card_tokens`, `card_tokens_prose`, `_seeded_index`)
- `data/board.json` (templates, meeting)
- `data/events/board_meeting.json`, `data/events/board_meeting_week1.json`
- `autoload/GameData.gd` (board data validation)
- `tests/test_board_meetings.gd`, `tests/test_events.gd`
- `CODEMAP.md` (`board_meetings.gd`, `board.json` rows), `docs/REFERENCE.md` §3.15, `docs/biz-meetings-vision.md` (Running order)
- Spec: `.scratch/board-meetings/debate-rework.md` (whole), `.scratch/board-meetings/spec.md`

**Status:** ready-for-agent

- [ ] Meeting runs with 1, 2 and 3 offered goals; no empty cards
- [ ] Same week + seed yields identical scene (Rewind-safe); context is plain data
- [ ] Vote options and chosen/concede lines verified; board_choose / board_skip effects unchanged
- [ ] Data lint: every template has `case`; unfilled `{}` tokens fail
- [ ] CODEMAP rows (<400 chars), REFERENCE §3.15 and vision doc updated
- [ ] Human on-device check list in the report (read order, vote card readable)
