# 05 — Component info bubble stays on screen

**What to build:** Tapping a component (e.g. a Lens) opens an info bubble that runs off the screen. The bubble must always fit within the viewport at phone width: clamp its position inside a 16px gutter, cap its width, wrap text, and use a smaller text size so it fits.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/dial_menu.gd` (info tag), `systems/lenses.gd` (`one_line`, `effect_rows` text), `docs/ui-vision.md` (typography).

**Status:** ready-for-agent

- [ ] Bubble never extends past any screen edge (16px gutter) for Lens, Movement and Complication taps, overview and section views
- [ ] Width capped, text wraps; font size reduced per ui-vision typography
- [ ] Bubble near an edge flips/shifts rather than clipping
