# 02 — App icon asset contract + app tile component

**What to build:** A reusable, standalone app-tile component (icon + label + badge dot + locked state) and the asset contract it loads icons against, demoable/testable in isolation before any screen uses it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Asset path/size/naming convention documented for imported app-icon textures
- [ ] Icons load as imported `Texture2D` assets — never emoji, never the `Icons.draw_*` glyph set (that mechanism stays reserved for map/legend glyphs)
- [ ] When an icon texture is absent, the tile falls back to a legible text label instead of failing to render
- [ ] Tile supports a locked visual state: greyed out, padlock overlay (reuses the existing padlock drawing), in all cases occupying its normal slot rather than being hidden
- [ ] Tile supports a badge dot for unread/attention state, driven by a boolean input (wiring to real predicates happens in ticket 07)
- [ ] Unit tests cover: normal render, missing-texture fallback, locked render, badge-on/off render
- [ ] No emoji anywhere in this component's code or default strings
