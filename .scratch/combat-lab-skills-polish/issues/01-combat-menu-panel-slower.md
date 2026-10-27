# 01 — Combat menu panel slide slower

**What to build:** In the combat command dock, the panel swap animations when switching menus (Fight, Item, etc.) feel too fast. Make them run at roughly 2× their current duration. Durations stay data-driven.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/combat_visuals.json` (`pacing.menuPanel`), `scenes/components/combat_command_dock.gd` (panel slide, reads `pacing.menuPanel`), `systems/combat_pacing.gd` (normal/quick pacing toggle — keep quick mode proportionate).

**Status:** ready-for-agent

- [ ] Fight ↔ Item (and other menu) panel swaps take ~2× the previous duration
- [ ] Change is in data only (no hard-coded durations)
- [ ] Quick pacing mode still faster than normal
