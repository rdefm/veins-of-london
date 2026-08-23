# 67 — Map tab: camera remembers last position instead of auto-focusing

**What to build:** A prior ticket (53) made the Map tab auto-frame the player's veins on open and persist camera state within a session, but the human reports it still doesn't reliably land on the player's veins. Change the behaviour instead of continuing to chase auto-focus: the Map tab camera should simply remember exactly where the player left it (zoom + scroll) and return there every time the tab is reopened. Auto-framing player veins is no longer the goal.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reopening the Map tab restores the exact zoom/scroll position the player last left it at, however many times the tab is switched away from and back.
- [ ] The very first time a save opens the Map tab (no persisted position yet), the camera centers on the player's single starting vein at the default zoom level — not a bounding-box-of-all-veins framing.
- [ ] Persisted position survives app restart (same save).
- [ ] Existing fit-to-veins framing logic is no longer invoked for the normal reopen path (only for the one-time first-open default above).
- [ ] Manual check noted for the human: open Map tab, pan/zoom somewhere specific, switch to another tab and back — confirm it returns exactly there. Then check a fresh save's first Map open lands on the starting vein.
