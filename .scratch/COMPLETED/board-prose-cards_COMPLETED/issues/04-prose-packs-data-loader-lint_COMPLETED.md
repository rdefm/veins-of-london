# 04 — Prose packs: data, loader, lint

**What to build:** meeting prose moves out of the board data into **prose packs**: one per board template (ladder goal), plus `_debate` (opener, reply, rebuttal, clash, chosen, concede) and `_week1` (explainer). Each prose card has `id`, `slot`, `voice`, optional `weight` and `cards` (event cards). `when` and `replies` are allowed by the schema but not yet acted on (05/06). GameData loads the packs at boot; the board system reads prose only from them. Template mechanics (label, tiers, rewards, premise) stay in the board data. For the same seed and week, meetings are unchanged (03's golden runs still match).

Load lint rejects: unknown slot or voice, invalid event card, duplicate prose card id across packs, a pack naming an unknown template, and any template with a pitching voice (alt voices included) that has no case card without a `when`.

Also append a `## Comments` note to `.scratch/board-meetings/issues/` tickets 18, 20, 22, 24 and 26: their prose now goes into that goal's prose pack (schema in this spec).

**Blocked by:** 03 — Board meeting on the splice skeleton

**Relevant files:**
- `autoload/GameData.gd` — board table load (`BOARD_TEMPLATES`, `BOARD_MEETING`, table list ~line 580)
- `data/board.json`; `data/board_prose/` (new)
- `systems/board_meetings.gd`
- `tests/test_gamedata.gd`, `tests/test_board_meetings.gd`
- `CODEMAP.md` (new data row); `docs/REFERENCE.md` §3.15
- Spec: `.scratch/board-prose-cards/spec.md` → "Prose pack schema", "Load lint"

**Status:** ready-for-agent

- [ ] No prose strings (case, debate lines) left in the board data; all prose lives in packs
- [ ] 03's golden runs still match
- [ ] Each lint rule has a failing-fixture test with a clear message; the shipped packs pass
- [ ] CODEMAP and REFERENCE §3.15 describe the packs
- [ ] Comments appended to board-meetings tickets 18/20/22/24/26
