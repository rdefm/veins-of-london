# 101 — TopBar bag icon renders near-black, not lit amber

**What to build:** The bag/ticket button in the top-right of the status ticker is present and tappable, but its icon renders as a very dark grey against the ticker's black background — effectively invisible at a glance, even though the rest of the dot-matrix board renders in lit amber. Fix the bag icon's rendered colour so it matches the board's lit amber, like every other glyph on the ticker.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The bag icon on the top bar renders in the same lit amber as the rest of the dot-matrix board, not dark grey/near-black.
- [ ] Root cause confirmed (e.g. a colour override not reaching the icon's draw call, or a hardcoded stroke colour inside the icon-drawing code) rather than a colour value tweaked until it "looks right."
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: on-device, confirm the bag icon is clearly visible (lit amber) against the ticker at rest, not just on tap/hover.
