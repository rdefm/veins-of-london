# 14 — Asset production + integration

**What to build:** the asset list per N6 — paper texture (1536×2048, aged cream, no linework/text), 8 icon glyphs (home/pin/padlock/market/phone/bag/legend/news, 64px single-colour), and verification that the bundled font covers the 5 ore symbols (⧖ ↯ ✦ ⚄ ❋) on Android, with SVG-derived fallback textures if not.

**Blocked by:** 12 (needs the canvas to integrate assets into).

**Status:** ready-for-agent

- [ ] Paper texture present and applied as the map background (procedural-noise placeholder acceptable if AI generation isn't available)
- [ ] All 8 icon glyphs present, single-colour and tintable, or implemented as `_draw()` polygons
- [ ] Android font-coverage check performed for all 5 ore symbols; fallback textures added if any glyph is missing
- [ ] No additional/commissioned art introduced beyond this list
- [ ] Human visual QA: confirm all icons and the ore symbols render correctly on an actual Android device or emulator
- [ ] `godot --headless --check-only --script` clean on all touched files
