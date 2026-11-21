# 09 — Dial menu: swap in the real art

**What to build:** Replace the placeholder shapes in the new Dial menu with sprites cut from the exploded master (`assets/hq/dial/dial_exploded_source.png`) plus the generated and hand-made component art in the revised 06 art spec. There is no assembled image and there are no hatch or iris strips. The menu assembles the four module layers (head, grip, lens collar, canopy) in code from anchors, and animates them. Selecting a section separates the modules. Movement and Lenses slide **out of the top lip** of their module and hover above it; Complications show the canopy's cut face, mark the chambers that can take a Complication, and play a small icon dropping into the chosen chamber on load. Timings, offsets, zoom rects and anchors live in data (e.g. `data/dial_art.json`), not in code constants. Decide **vertical vs horizontal** with the human here (the spec covers both; prompts target vertical).

Steps, in order:

1. **Prepare the sprites (with the human).** Run the exploded sheet through the pixelizer (`tools/pixelizer.html`, or `.claude/skills/event-storyboard/scripts/pixelize.py`) as a whole, snap to the palette, remove the background, and cut the four module PNGs. Hand-make `dial_stud_lit`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_glow`, the tier overlays and the `comp_label_*` icons. Generate the Lens (P1), Movement (P2), tag (P3), bench (P4) and shadow (P5) sprites, each pixelised. Measure the anchors from the cut sprites (art spec §2.3) into data.
2. **Wire the layers.** Assemble by anchor (`seat` into the next module's `top_lip`, overlap `seat_depth`). Hide the old placeholder rects, the hatch tween and the iris shutters.
3. **Beats.** Section split, hover bob, emerge and re-enter (clipped at the lip's `clip_y`), canopy drop, chamber pulse and icon drop, load / swap / unload, Wind, Back (art spec §4). Reduced motion becomes a 0.1 s crossfade with no hover.

**Blocked by:** 06 — Dial menu art brainstorm; 08 — New Dial menu: Movement and Complication sections, Craft

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md` (parts §2, anchors §2.3, layouts §3, beats §4, prompts §5)
- `assets/hq/dial/dial_exploded_source.png`, `assets/hq/dial/`, `assets/combat/icons/` (sources for the hand-made complication labels)
- `tools/pixelizer.html`, `tools/pixel_grid.py`, `.claude/skills/event-storyboard/scripts/pixelize.py`
- `scenes/components/dial_menu.gd` (placeholder rects, `SECTIONS`, `_apply_view`, hatch and iris code to remove)
- `scenes/screens/hq_dial.gd`
- `docs/ui-vision.md`, `docs/ART-BIBLE.md`

**Status:** ready-for-agent

- [ ] Four module layers cut from the pixelised master, each transparent and on the native grid; anchors measured into data
- [ ] The Dial assembles from the layers by anchor; no placeholder shapes, hatch tween or iris code left
- [ ] Movement and Lenses emerge from the lips and hover (whole-pixel bob, shadow); locked Lens slots show a ghost
- [ ] Complications: canopy drops, chambers pulse when they can take one, a loading icon drops into the chosen chamber, blanks cover chambers above `capacityMax`, studs light per loaded chamber
- [ ] Beats match the spec; reduced motion crossfades with no hover; timings, offsets and anchors in data
- [ ] Orientation decision recorded in the spec
- [ ] Human on-device check of every section's zoom in/out
