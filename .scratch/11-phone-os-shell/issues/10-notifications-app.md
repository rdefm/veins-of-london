# 10 — Notifications app

**What to build:** A new Notifications app, reachable from the grid, browsing the full persistent notification log built in ticket 04.

**Blocked by:** 07 (phone home grid), 04 (notification log + toast rework)

**Status:** ready-for-agent

- [ ] Player can open Notifications from the app grid
- [ ] Shows the full log, newest first
- [ ] Read-only — no actions available from entries
- [ ] Respects the 50-entry cap and `seen` flag from ticket 04 (entries display regardless of `seen` state, but the flag is available for potential visual distinction)
- [ ] Screen-level test confirms log renders in correct order and respects the cap
