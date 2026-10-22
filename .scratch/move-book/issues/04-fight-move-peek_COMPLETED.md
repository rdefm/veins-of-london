# 04 — Long-press a move in a fight

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR), placement "3 · In the fight · Long-press". If this ticket and the mock disagree, stop and ask.

**What to build:** In a fight, holding a move in the command dock shows a small read-only peek above it: move name and level, its current effects (stat value + any earned unlocks), and "Next, Lv{n}: {gain} ({XP} XP)". Releasing closes it. A tap still plays the move exactly as now. No state change, so Rewind and the fight are untouched. Strings come from the same data as 02.

**Blocked by:** 02 — Move Book in the Profile app.

**Relevant files:**
- `scenes/components/combat_command_dock.gd` (move rows, `_build_level_badge`, existing tooltip/"?" popover)
- `scenes/screens/combat_rounds.gd`
- `systems/move_levels.gd` (helper from 02)
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Long-press shows the peek; tap still plays the move
- [ ] Peek content matches the Move Book for the same move and level
- [ ] Works for Leg it and with the dock locked/disabled rows
- [ ] Human check: long-press feel and peek legibility on-device
