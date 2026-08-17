# 09 — Save/Load app

**What to build:** A single new Save/Load app, reachable from the grid, holding all save-related actions in one place, replacing the You tab's Save & Load button.

**Blocked by:** 07 (phone home grid)

**Status:** ready-for-agent

- [ ] Player can open Save/Load from the app grid
- [ ] Three save slots, each with Save / Load / Delete
- [ ] Export and Import actions
- [ ] New Game action, gated behind an explicit confirmation step — no destructive action in this app commits on a single tap
- [ ] Screen-level test confirms the confirm-gate actually blocks a single-tap New Game commit
- [ ] Tests confirm save/load/delete/export/import behave identically to today's equivalent actions
