# 113 — Shared symbol-glyph fallback helper

**What to build:** The bundled Godot engine font has no glyphs for the 5
ore-type unicode symbols (⧖↯✦⚄❋) or several other unicode glyphs used as plain
text — confirmed via `OreGlyphs.font_covers_all_symbols()`, already `false` on
the bundled font, and already worked around on the Network map (`MapCanvas`
falls back to `OreGlyphs`' hand-drawn vector glyphs whenever the font check
fails). Build a small, reusable Control (or equivalent helper) that renders a
symbol as a hand-drawn vector glyph in place of a Label whenever the font
doesn't cover it, so every other screen can adopt the same fallback `MapCanvas`
already uses instead of reimplementing font-coverage checking per call site.
This ticket delivers the helper itself, tested standalone — wiring it into
every remaining menu is ticket 114.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A reusable helper exists that renders a given symbol as a vector glyph
      fallback when `Font.has_char()` (or an `OreGlyphs.
      font_covers_all_symbols()`-style check) fails, and as normal text
      otherwise.
- [ ] Covers at minimum the 5 ore-type symbols; extensible to any other
      unicode glyph found tofu'd elsewhere during ticket 114's sweep.
- [ ] Unit-testable without a live SceneTree font-rendering pass (same
      "off-tree testable" convention this codebase already uses elsewhere),
      or clearly documented if that's not achievable for this specific case.
- [ ] Not yet wired into any menu screen — this ticket is the helper only.
