# 31 — Ladder ownership: Archie holds the reserve; James can pitch Guild-beating share_leader

**What to build:** `fin_reserve` is pitched by Archie (his want: cash so bills stop being scary), not James. `share_leader` can be pitched by either Archie or James; James's version is an alternate template framed around beating the Guild as a standard (never a live-state claim). The agenda still offers at most one card per voice, and the same rung is never offered twice in one week. Placeholder `case` lines for the new variants are fine; tickets 33/34 write the prose.

**Blocked by:** 30 — Debate skeleton and data model

**Relevant files:**
- `data/board.json` (ladders `financial`, `market_share`; templates; `voices`)
- `systems/board_meetings.gd` (`eligible_cards`, `_build_card`, `agenda`, `_cards_by_voice`)
- `tests/test_board_meetings.gd`
- `docs/REFERENCE.md` §3.15, `docs/biz-meetings-vision.md` (ladder table)

**Status:** ready-for-agent

- [ ] `fin_reserve` card voice is Archie
- [ ] `share_leader` can appear with either voice, never both in one agenda; goal/tiers/rewards identical
- [ ] Voice weight/warmth bookkeeping credits whichever voice pitched
- [ ] Tests cover both voices and the no-duplicate rule
