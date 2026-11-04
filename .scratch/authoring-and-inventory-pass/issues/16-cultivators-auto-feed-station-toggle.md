# 16 — Cultivators auto-feed, with station toggle

**What to build:** Before pruning or cultivating, a cultivator checks Root Feed on the vein it is working. It applies one unit at the lowest tier held when the station toggle is on, growth is below the station target, Root Feed is not already running and the shared pool holds some. Applying costs no action. The per-station toggle is saved, backfilled on load, defaults on, and appears wherever the player sets a station's target. Use is recorded in the production or station log, or the nearest existing staff report.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/rooms.gd`, `systems/cultivating.gd`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `scenes/components/vein_bubble.gd`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_rooms.gd`, `tests/test_cultivating.gd`, `tests/test_savemanager.gd`, REFERENCE.md §3.4 Cultivating & pruning, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Block-step tests cover each rule: toggle off, at or above target, already fed, empty shared pool
- [ ] Lowest tier is used first
- [ ] Stashed feed is never used
- [ ] The cultivator still takes its normal action on the same step
- [ ] Each use is recorded where the player can see it
- [ ] Old saves load with the toggle backfilled to on
- [ ] REFERENCE.md §3.4 is updated
- [ ] New strings are flagged `PROSE-REVIEW:`
- [ ] Human QA block lists the toggle in both places
