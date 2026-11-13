# 07 — Map rebuild cache

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** The Map skips its full rebuild when nothing layout-relevant changed. A system-layer `Sites.layout_signature()` summarises site/vein ids, owners and growth bands; the Map compares it plus pending-event ids, active contact pins and dark-mode flag with the last one, and only queues a redraw if equal. A cash-only change costs <1 ms instead of ~46 ms.

**Blocked by:** 03 (eventbus-mark-changed)

**Relevant files:** `scenes/components/map_canvas.gd` (`_rebuild`, ~line 419), `systems/sites.gd`, map layout/events/pins/palette helpers (confirm names by grep), `tests/test_map_canvas.gd`; review §2.2

**Status:** ready-for-agent

- [ ] Cash-only state change does not rebuild (tested)
- [ ] Site/vein/owner/growth change does rebuild (tested)
- [ ] Map stays read-only; signature logic lives in the system layer
- [ ] Human check: map looks identical across a day rollover
