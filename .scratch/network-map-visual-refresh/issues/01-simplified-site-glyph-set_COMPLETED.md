# 01 — Simplified site glyph set

**What to build:** Replace the Network map's existing ore glyph drawings with the simplified silhouettes in **Photo 1 — Site Type Glyphs**: Time hourglass, Fate dice, Life sprout, Physics lightning bolt, Emotion heart. Retain the canonical `fate` ID/name despite Photo 1 saying “Chance”. Redraw/tune all five as one coherent, solid vector set with consistent optical weight and sizing inside the standard circular marker; do not merely swap Life and Emotion while leaving the other three visually mismatched.

**Mockup:** [`../mockups/01-site-type-glyphs.jpg`](../mockups/01-site-type-glyphs.jpg) is authoritative for silhouette, simplicity, optical weight, and relative scale. [`../mockups/02-expanded-faction-key-map.jpg`](../mockups/02-expanded-faction-key-map.jpg) and [`../mockups/03-site-card-map.jpg`](../mockups/03-site-card-map.jpg) are secondary checks for legibility at actual map size.

**Blocked by:** None — can start immediately.

**Status:** completed

**Relevant files:** `scenes/components/ore_glyphs.gd`; `scenes/components/map_canvas.gd`; `tests/test_ore_glyphs.gd`; `tests/support/draw_spy.gd`; `docs/M1.5-NETWORK-MAP.md` §N2 and §N6; `docs/ui-vision.md`; `data/ore_types.json` (read only; IDs/names do not change)

- [ ] `OreGlyphs.SHAPES` still covers exactly the five canonical IDs: `time`, `physics`, `life`, `fate`, `emotion`.
- [ ] Vector fallbacks render hourglass, die, sprout, lightning bolt, and heart respectively; no reliance on unsupported font glyphs.
- [ ] All five use a coherent solid-charcoal visual weight and fit without clipping at every marker size used by `MapCanvas`.
- [ ] No ore ID/name/data change: Fate remains `fate`/“Fate”; “Chance” appears nowhere in code, data, docs, or UI.
- [ ] Glyph drawing stays independent of fullness, growth band, ownership, and security state.
- [ ] `tests/test_ore_glyphs.gd` is updated to verify dispatch and the meaningful drawing primitives/geometry for sprout and heart, plus regression coverage for the other three.
- [ ] `docs/M1.5-NETWORK-MAP.md` glyph grammar/asset text is updated to name the approved silhouettes rather than the retired symbol set.
- [ ] Godot 4.7 syntax checks pass for touched `.gd` files; full suite passes.
- [ ] Human QA: each shape reads instantly at default/minimum practical zoom, appears centred, and has comparable visual weight. Report exact on-device checks.
