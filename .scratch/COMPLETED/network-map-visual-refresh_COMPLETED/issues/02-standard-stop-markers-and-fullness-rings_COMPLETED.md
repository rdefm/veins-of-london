# 02 — Standard stop markers and fullness rings

**What to build:** Standardise player-owned, faction-owned, and unclaimed site stops around the Photo 1 grammar: consistent white circular centre, charcoal ore glyph, and an external radial ring. Remove the current growth-filled disc/status colouring from the glyph/centre. For claimed sites, the ring shows vein fullness (`growth / Cultivating.ceiling(vein)`); for unclaimed sites, it is empty (neutral full-circumference track, zero progress). Default progress is restrained gold over a muted neutral track. Preserve all existing interaction and map semantics outside this visual carrier.

**Mockups:** [Photo 1](../mockups/01-site-type-glyphs.jpg) is authoritative for marker construction and progress-ring treatment. [Photo 2](../mockups/02-expanded-faction-key-map.jpg) is authoritative for how those markers should read among ownership lines at phone scale. [Photo 3](../mockups/03-site-card-map.jpg) supplies the cream/charcoal/gold palette relationship.

**Blocked by:** 01 — Simplified site glyph set.

**Status:** completed

**Relevant files:** `scenes/components/map_canvas.gd`; `scenes/components/ore_glyphs.gd`; `systems/map_style.gd`; `systems/cultivating.gd`; `tests/test_map_canvas.gd`; `tests/test_map_style.gd`; `tests/support/draw_spy.gd`; `docs/M1.5-NETWORK-MAP.md` §N2 and §N4; `docs/REFERENCE.md` §1.2

- [ ] Player, faction, and unclaimed stops share the same white centre/charcoal-glyph grammar and consistent base visual diameter; ownership still reads from Network lines.
- [ ] Claimed fullness arc equals clamped `growth / Cultivating.ceiling(vein)` for both player and faction veins; 0 is empty and ceiling is a full circle.
- [ ] Unclaimed sites show the complete neutral track and no progress arc.
- [ ] The current `_draw_growth_fill` filled-disc treatment is removed/replaced; fullness/status never recolours or fills the white centre and never recolours/deforms the glyph.
- [ ] Default ring has muted neutral remainder and restrained gold progress as in Photo 1. Type/Growth/other filters retain their existing information and fade behaviour by styling the ring/arc where necessary, without violating the white-centre/charcoal-glyph rule.
- [ ] Rich/saturated sites and veins retain a distinct second concentric interchange/terroir ring; it cannot be mistaken for fullness.
- [ ] Security padlocks, wild/rampant halo, danger ring, queued map animations, drawing order, route joining, and stop hit-testing remain functional.
- [ ] Existing tap target sizes do not shrink even if visual radii are retuned.
- [ ] Tests cover empty/partial/full arc geometry, ceiling 100 and 120, unclaimed empty rings, player/faction parity, filter styling, and rich/saturated second rings.
- [ ] `docs/M1.5-NETWORK-MAP.md` is amended from radial disc fill to the approved external progress-ring grammar.
- [ ] Godot 4.7 syntax checks pass for touched `.gd` files; full suite passes.
- [ ] Human QA: marker/glyph legibility at default and minimum practical zoom; 0/partial/full differences; dense-cluster clarity; rich/saturated distinction; every filter mode. Report exact on-device checks.
