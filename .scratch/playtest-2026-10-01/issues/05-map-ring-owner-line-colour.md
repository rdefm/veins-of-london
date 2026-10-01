# 05 — Map: vein cultivation ring uses owner's tube-line colour

**What to build:** On the Map tab the ring that fills to show a vein's cultivation is always orange. It should use the colour of the vein owner's tube line (player's line for player veins, each faction's line colour for theirs), including the fill animation/halo.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/map_canvas.gd` (FULLNESS_RING_*, ring draw + tween), `scenes/components/map_halos.gd`, `data/map_palette.json`, `map_palette.gd`, `docs/M1.5-NETWORK-MAP.md` glyph grammar.

**Status:** ready-for-agent

- [ ] Ring colour derived from owner line colour (palette id, no hardcoded colour)
- [ ] Works in light + Map dark mode
- [ ] Human check: player and each faction's veins show rings in their line colour
