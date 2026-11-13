# 06 — Debug: skip to Sunday evening

**What to build:** A debug-mode button advances time to the Sunday evening time block, running the daily tick for every skipped day, so the player can consume that block and the weekly board meeting begins without waiting a real week.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/debug_tools.gd` (near `board_jump_to_meeting` ~L28), `systems/time_system.gd`, `systems/board_meetings.gd`, the debug panel/screen under `scenes/`, `autoload/GameState.gd`, tests for debug tools.

**Status:** ready-for-agent

- [ ] Button visible only in debug mode
- [ ] Skipped days run normal daily ticks (income, upkeep, faction sim); no day/block skipped silently
- [ ] Lands with Sunday evening block available; consuming it starts the board meeting
- [ ] No-op/safe if already on Sunday evening; capped loop in tests
- [ ] CODEMAP updated if files' responsibilities change
