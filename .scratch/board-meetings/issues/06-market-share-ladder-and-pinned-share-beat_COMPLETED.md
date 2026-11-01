# 06 — Market share ladder (Archie) + pinned Act 2 share beat

**What to build:** Archie's **Market share** ladder (x% of one ore's production → higher % → market leader → second ore at x%), tracked by a new `ore_share_at_least` condition reading the Shares 7-day window. Its first rung is the Act 2 spine's first beat (reach ~25% in one ore type), **pinned**: it holds one agenda slot every week until taken, the player may pass on it, and passing keeps it next week. Spine state lives in board state and the Act 2 beats show as ToDo items (active/done/placeholder like other questlines). Placeholder tiers: base 20% / target 25% / stretch 30%. Premise truth: the card names an ore the simulation actually supports (real share/demand).

**Blocked by:** 02 — Board core + Financial ladder (James); 03 — ToDo Board section + Today Story row

**Relevant files:**
- `systems/shares.gd` — `window_totals()`, producers
- `systems/objectives.gd` — new `ore_share_at_least`
- `systems/board_meetings.gd`, `data/board.json` — ladder, `pinned` / `spine` fields
- `systems/todo.gd` — Act 2 spine items
- `tests/test_board_meetings.gd`, `tests/test_objectives.gd`, `tests/test_todo.gd`
- `.scratch/biz-empire-act2/spec.md` stories 93–104 (superseded questline, for beat intent)
- Spec: §"Act 2 spine rules", §"Data" placeholder tiers

**Status:** ready-for-agent

- [ ] `ore_share_at_least` threshold tests
- [ ] Pinned card present every week until taken; passing keeps it next week; other two slots stay free
- [ ] Completing it marks spine beat 1 done (beat 2 unlock hook)
- [ ] Later rungs open from real state, not from prior rungs; already-met rungs skipped
- [ ] Act 2 beats visible in ToDo
