# 01 — Map dark mode: stronger district-owner zone tint

**What to build:** In Map dark mode, the district owner's zone colour blends into the background. Strengthen it (more saturated/opaque fill and a firmer outline) so ownership reads at a glance. Light mode unchanged. Colours stay data-driven via the map palette's dark-only overrides.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/map_palette.json`, `scenes/components/map_palette.gd`, `systems/map_style.gd` (`zone_fill_kind`), `scenes/components/map_canvas.gd`, `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Dark mode: player, faction and contested zone tints clearly distinct from the background
- [ ] Light mode visuals unchanged
- [ ] No hard-coded colours in code; values live in the palette data
- [ ] Map style / palette tests pass
