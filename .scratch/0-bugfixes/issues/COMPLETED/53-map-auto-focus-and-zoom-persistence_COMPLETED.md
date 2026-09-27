# 53 — Map: auto-focus on first open, remember zoom/pan thereafter

**What to build:** `zoom_level` is currently a plain `MapCanvas` instance var initialized to `MapZoom.DEFAULT` (`map_canvas.gd:146`, 0.85) — since the whole Map screen/`MapCanvas` is torn down and recreated on every navigation to `map` (`map_events.gd:14-16` comment), zoom and pan reset to default every time the map is reopened, with no auto-focus-on-player-veins logic anywhere. Per the human: the *first ever* time the map is opened, it should center/zoom on the player's veins; every subsequent open should restore exactly the zoom/pan the player left it at, not re-auto-focus.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New persisted state (in `GameState.state`) tracks whether the map has ever been opened before, plus the last zoom level and pan/scroll position.
- [ ] On the very first map open (state not yet set), the view centers and zooms to frame the player's veins (compute a bounding view over `player.veins` positions), then marks first-open as done.
- [ ] On every subsequent open, the view restores the persisted zoom/pan exactly, ignoring auto-focus.
- [ ] Persisted state survives save/load (covered by `SaveManager`'s wholesale state dump — confirm no int/float restoration gap for the new fields, following the pattern in `SaveManager._restore_*_int_types()`).
- [ ] New test confirming first-open auto-focus behavior and subsequent-open persistence, including across a save/load round-trip.
- [ ] Manual check noted for the human: on a fresh game, confirm the first map open centers on your veins; zoom/pan elsewhere, close and reopen the map (and reload a save) and confirm it's exactly where you left it.
