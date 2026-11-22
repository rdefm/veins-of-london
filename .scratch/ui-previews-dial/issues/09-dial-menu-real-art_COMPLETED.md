# 09 — Dial menu: swap in the real art

**What to build:** Replace the placeholder shapes in the new Dial menu with sprites cut from the exploded master (`assets/hq/dial/dial_exploded_source.png`) plus the generated and hand-made component art in the revised 06 art spec. There is no assembled image and there are no hatch or iris strips. The menu assembles the four module layers (head, grip, lens collar, canopy) in code from anchors, and animates them. Selecting a section separates the modules. Movement and Lenses slide **out of the top lip** of their module and hover above it; Complications show the canopy's cut face, mark the chambers that can take a Complication, and play a small icon dropping into the chosen chamber on load. Timings, offsets, zoom rects and anchors live in data (e.g. `data/dial_art.json`), not in code constants. Decide **vertical vs horizontal** with the human here (the spec covers both; prompts target vertical).

Steps, in order:

1. **Prepare the sprites (with the human).** Run the exploded sheet through the pixelizer (`tools/pixelizer.html`, or `.claude/skills/event-storyboard/scripts/pixelize.py`) as a whole, snap to the palette, remove the background, and cut the four module PNGs. Hand-make `dial_stud_lit`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_glow`, the tier overlays and the `comp_label_*` icons. Generate the Lens (P1) and Movement (P2) sprites, each pixelised. The info tag keeps the existing code-built panel, and the bench backdrop and floor shadows are deferred (ticket 13). Anchors are already measured into `data/dial_art.json`; re-check them against the final sprites.
2. **Wire the layers.** Assemble by anchor (`seat` into the next module's `top_lip`, overlap `seat_depth`). Hide the old placeholder rects, the hatch tween and the iris shutters.
3. **Beats.** Section split, hover bob, emerge and re-enter (clipped at the lip's `clip_y`), canopy drop, chamber pulse and icon drop, load / swap / unload, Wind, Back (art spec §4). Reduced motion becomes a 0.1 s crossfade with no hover.

## Progress (2026-11-21)

**Done**
- Exploded master saved: `assets/hq/dial/dial_exploded_source.png`. Pixelised at x3 (`.scratch/ui-previews-dial/Disassembled Steampunk Umbrella Modules_pixel_x3.png`).
- Four module layers cut at native size, transparent, lossless: `assets/hq/dial/dial_head.png` (86x78), `dial_grip.png` (120x135), `dial_lens_collar.png` (83x70), `dial_canopy.png` (72x153).
- Anchors measured into `data/dial_art.json` (seats, top-lip ovals + `clip_y`, face/studs, intake, ports, chambers, assembled origins, hover offsets, component sizes). An assembled preview checked: the layers stack and the seams close. Anchors were eyeballed from gridded enlargements, so expect small tweaks on screen.
- Spec and prompts revised (`dial-art-spec.md`, `dial-image-prompts.md`); sizes rescaled to the real modules (Lens 20x20, Movement frame 40x40, icon 12x12, chamber 22x8).

**Outstanding, needs the human (arriving next session)**
Pixelise each generated image at the same scale as the sheet (x3) and give me the file paths. I will place them.
- `lens_time` (20x20) from prompt P1 in `dial-image-prompts.md`.
- `movement_recharge` (4-frame strip, 160x40) from prompt P2.
- Only one of each for the proof pass. The other four Lenses and three Movements are in ticket 13.

**Outstanding, agent (needs no human art)**
- Make the small overlays as native-grid PNGs by script, for the human to review: `dial_stud_lit`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_glow`, `lens_tier_<n>`, `movement_tier_<n>`.
- Make `comp_label_<recipeKey>` (12x12) by downscaling the `assets/combat/icons/` art, for the human to review.
- Place the Lens and Movement sprites under `assets/hq/dial/components/`.
- Wire the layers and beats in `DialMenu` (steps 2 and 3 above); remove the placeholder rects, hatch tween and iris code; update tests and CODEMAP.

**Decisions still open**
- Vertical vs horizontal layout (human, before the work is finished). The spec's vertical numbers are the default.
- A 12x12 icon sits above a 22x8 chamber, so it stands on the chamber rather than inside it. Check on device and adjust.
- Zoom scales: the modules are about 1.4x the size the spec assumed, so Lenses and Complications probably zoom at x2 or x3, not x4. Set in `data/dial_art.json` once on screen.

**Blocked by:** 06 — Dial menu art brainstorm; 08 — New Dial menu: Movement and Complication sections, Craft

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md` (parts §2, anchors §2.3, layouts §3, beats §4, prompts §5)
- `assets/hq/dial/dial_exploded_source.png`, `assets/hq/dial/`, `assets/combat/icons/` (sources for the hand-made complication labels)
- `tools/pixelizer.html`, `tools/pixel_grid.py`, `.claude/skills/event-storyboard/scripts/pixelize.py`
- `scenes/components/dial_menu.gd` (placeholder rects, `SECTIONS`, `_apply_view`, hatch and iris code to remove)
- `scenes/screens/hq_dial.gd`
- `docs/ui-vision.md`, `docs/ART-BIBLE.md`

## Done (2026-11-22)

- Human art in: `lens_time` (20x20) and `movement_recharge` (4 frames, 160x40; the frames are near-identical, so the spin is wired but barely visible). Sources kept in `.scratch/ui-previews-dial/sources/`; `tools/dial_art_build.py` grid-locks them and draws every overlay, tier mark and `comp_label_*` (19 from combat icons + placeholder fallback).
- `DialMenu` rebuilt on the module sprites; anchors, framing, offsets and timings in `data/dial_art.json` (`GameData.DIAL_ART`). Vertical layout. Missing Lens ores fall back to `lens_time` tinted; missing Movements to `movement_recharge`.
- Needle stays code-drawn (`dial-needle.png` is 666x375, not the 6x18 sprite the spec assumes).
- Wind via the 2+ Lens ore-choice modal skips the spin beat (only the direct one-Lens Wind plays it).

**Status:** ready-for-agent

- [x] Four module layers cut from the pixelised master (done: `assets/hq/dial/dial_{head,grip,lens_collar,canopy}.png`) and anchors measured into `data/dial_art.json` (done); the final check remains
- [x] The Dial assembles from the layers by anchor; no placeholder shapes, hatch tween or iris code left
- [x] Movement and Lenses emerge from the lips and hover (whole-pixel bob, no shadow); locked Lens slots show a ghost
- [x] Complications: canopy drops, chambers pulse when they can take one, a loading icon drops into the chosen chamber, blanks cover chambers above `capacityMax`, studs light per loaded chamber
- [x] Beats match the spec; reduced motion crossfades with no hover; timings, offsets and anchors in data
- [x] Orientation decision recorded in the spec
- [ ] Human on-device check of every section's zoom in/out
