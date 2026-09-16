# 01 — Background & glyph contrast pass

**What to build:** Finalize the flat off-white background colour for the Network map (classic tube-map look — the aged-paper texture is already gone, per the Chunk 3 pivot in `scenes/components/map_canvas.gd`'s `_draw_paper()`, which left the colour unchanged and flagged "full palette redesign is a later Chunk 3 ticket"). Pick the exact off-white/light tone, then walk the existing glyph grammar (N2) — line colours (player amber, each faction colour, NPC grey stubs), stop rings, badges (level/security), halos, danger ring, and zone-fill tints — against that background and adjust any that read poorly for contrast. No redesign of the grammar itself (shapes, sizes, what each glyph means stay exactly as N2 specifies) — recolour/reposition only, per the PRD.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `PAPER_COLOUR` in `map_canvas.gd` is set to the finalized off-white tone (may be unchanged from `#f0ece2` if it already reads well — this ticket is the decision point, not a mandate to change it).
- [ ] Each existing glyph/line colour (player amber, all 5 faction colours from `factions.json`, NPC grey `#8a8a8a`, `--muted`, `--ink`, `--slate`, `--danger`, warded `#7b68ee`, guarded/`--success`) is legible against the finalized background — adjust any that fail a quick contrast check, otherwise leave as-is.
- [ ] Zone-fill alpha (`ZONE_ALPHA`, 8%) still reads as a subtle tint, not invisible or overpowering, against the finalized background.
- [ ] No change to glyph shapes, sizes, draw order, or what any filter mode does — this ticket is colour values only.
- [ ] All 5 existing filter modes (Ownership/Type/Strength/Charge/Security) still look correct on the new background — quick visual re-check, not a logic change.
- [ ] Report lists exactly what a human should check on-device (background tone in daylight/indoor screen conditions, glyph legibility at 1x zoom).
