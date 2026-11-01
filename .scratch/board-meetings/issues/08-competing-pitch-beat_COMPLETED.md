# 08 — Competing-pitch beat

**What to build:** occasionally two agenda cards compete for the same thing as a flavour beat (both want the same ore, the same cash), never a trap — picking either costs nothing on the other. Capped at no more than one week in five via `lastCompeting` and a tuning value. Flavour-text slot only; prose comes in the AOB prose ticket.

**Blocked by:** 05 — Monday meeting event + rollover + Act 1 hand-off

**Relevant files:**
- `systems/board_meetings.gd` — `agenda()`; `data/board.json` tuning
- `tests/test_board_meetings.gd`
- Spec: story 35, §"State" `lastCompeting`

**Status:** ready-for-agent

- [ ] Competing beat never occurs twice within the cap window (seeded test)
- [ ] Agenda determinism under Rewind preserved
- [ ] No penalty from either pick
