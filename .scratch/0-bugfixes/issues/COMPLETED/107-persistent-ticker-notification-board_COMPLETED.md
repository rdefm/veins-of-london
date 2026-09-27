# 107 — Merge ticker and notifications into one persistent scrolling board

**What to build:** Notifications currently float in as a separate toast component and auto-fade after a few seconds, capped at 2 visible at once. Replace this with a single persistent dot-matrix board (tube departure-board style) that carries both the live status ticker text and a scrolling notification log together: new messages scroll in, older ones scroll up and off, and nothing disappears via a fade timer. The board itself is always present, the same way the top ticker is today.

Reasonable defaults if not otherwise specified: keep a small fixed number of visible lines (e.g. 2–3) with older lines scrolling off the top as new ones arrive, using a scroll/scramble transition consistent with the existing dot-matrix board's style; retire the separate floating/fading toast component entirely in favour of the merged board.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Status ticker text and notifications render on one shared persistent dot-matrix board.
- [ ] Notifications no longer fade out on a timer — they scroll off only when displaced by newer messages.
- [ ] The separate floating toast component is retired (no remaining second notification surface).
- [ ] The board is always present on screen, never conditionally shown/hidden based on whether there's an active notification.
- [ ] Test coverage for the merged board's scroll/queue behaviour.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: trigger several notifications in quick succession, confirm they queue/scroll on the same board as the status ticker rather than floating and fading independently.
