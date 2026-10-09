# Plate compositor

Puts character sprites onto a blank reference plate (`assets/reference-plates/`) so they read as
*in* the room, not pasted on top. The background never changes between shots, so it stays
consistent when the cast changes.

Plain Python (Pillow + numpy). No AI in the loop: it's deterministic and free to re-run.

```
python tools/plate_compositor/compose.py tools/plate_compositor/shots/james_workshop_demo.json --sheet
```

Output goes to `.scratch/plate-compositor/` by default (`--out DIR` to change).

## Step by step

All coordinates are **native px** = full-res px ÷ `scale` (default 4; the workshop plate uses 5). Read
them off the full-res plate in any image editor (cursor position), then divide by the plate's `scale`.

### A. Make a shot on an existing plate

1. Copy `shots/james_workshop_demo.json` to `shots/<event_id>.json`. Set `"plate"` to the
   plate's file name without `.json`.
2. For each shot, give it an `id` (becomes the output file name) and a `label` (shown on the
   review sheet).
3. For each character, add an actor:
   - `sprite`: path to the character's **master** sprite (transparent PNG, e.g.
     `assets/character-references/James/James_biz_sprite_master.png`).
   - `feet_x`, `feet_y`: where the point between their feet touches the floor, in native px.
     Lower `feet_y` = closer to camera = bigger. Size is automatic.
   - `flip: true` to face the other way.
4. Run `python tools/plate_compositor/compose.py tools/plate_compositor/shots/<event_id>.json --sheet`.
5. Open `.scratch/plate-compositor/<event_id>_sheet.png` and check that:
   - the feet sit on the floor, not on furniture;
   - nobody overlaps furniture they should be behind (if they do, add an occluder, step D5);
   - the shadow sits under the feet.
   To fix one, nudge `feet_x`/`feet_y` by 2–5 px and re-run.
6. When happy, copy the shot PNG to `assets/events/<event_id>/<event_id>_card<N>.png`.

### C. Add an AI-posed character (leaning, sitting, holding things)

Sprites only stand. For a pose that touches the room, let the AI draw the character *on the
plate*, then cut them out so the AI's background drift never reaches the final image.

1. In ChatGPT, upload the **blank plate** and the character's master sprite. Prompt e.g.:
   "Add this man leaning his hip against the front-left corner of the desk, hands on its edge.
   Same pixel-art style and scale as the room. Change nothing else. Keep the exact image size."
   Ask for 3–4 variations; save the best one, e.g. `.scratch/event-art/<event_id>/lean_v2.png`.
2. Copy `poses/james_workshop_lean_desk.json` to `poses/<plate>_<character>_<pose>.json` and set:
   - `ai_image`: the saved AI image.
   - `region`: a loose outline around the character **plus anything they touch** (hand on desk,
     chair seat), as `polygon` `[[x, y], ...]` or `rect` `[x0, y0, x1, y1]`. **Full-res px
     here, not native.** Keep it tight-ish; drift inside the outline can sneak in.
   - `out`: where the cut-out goes, e.g. `assets/character-references/James/poses/workshop_lean_desk.png`.
3. Run `python tools/plate_compositor/extract.py tools/plate_compositor/poses/<file>.json --sheet`.
4. Open `.scratch/plate-compositor/<file>_extract_sheet.png`. The pink tint shows exactly what
   was kept and the cyan line is your outline. Fix problems as follows:
   - **Background bits kept:** tighten `region`, or raise `threshold` (default 60).
   - **Holes or missing edges on the character:** lower `threshold` to 40–50, or raise `close`
     (default 4).
5. In a shots file, add the actor as `{"cutout": "<out path>"}`. No position or size is needed
   because the cut-out is plate-sized and keeps its spot. Add `"shadow": true` only if the AI
   drew none. It mixes freely with normal sprite actors (`shots/james_workshop_lean_demo.json`).
   If the AI drew the character with finer pixels than the plate's `scale` and grid-locking
   blurs the face, add `"full_res": true`: the cut-out is pasted after the upscale, unsnapped,
   still behind anything with a lower floor position.

A cut-out only fits **that plate, that spot**. A different desk or room means generating again.

### D. Set up a new blank plate (once per room)

1. Put the blank plate (no characters) in `assets/reference-plates/`.
2. Copy `plates/james_workshop.json` to `plates/<plate_name>.json` and set `image`.
3. `scale`: the plate's apparent pixel size in full-res px. Zoom in and count how wide one
   "pixel" block is. Default 4 (omit the key): plate prompts ask for ~4×4 px art pixels, and
   ChatGPT draws characters at 3–4 px, so a coarser grid blurs faces. `james_workshop` stays 5
   because its coordinates were traced at 5.
   If small saturated props (crates, signs) come out grey or brown on the review sheet, set
   `"quantize": "octree"` and raise `plate_colours` to ~96 (`plates/mile_end_yard.json`).
4. `horizon_y`: the camera's eye level in native px, where a standing adult's eyes would
   be anywhere on the floor. Either take it from a test image with a person in it, or find
   where the floor and ceiling lines converge. If figures come out too big or too small,
   raise or lower it.
5. `occluders`: anything a character can stand behind (stools, chairs, desk fronts). Trace each
   one roughly with `ellipse`/`rect` `[x0, y0, x1, y1]`, `line` `[x0, y0, x1, y1]` + `width`,
   or `polygon` `[[x, y], ...]`. Set `depth_y` to where it touches the floor (its lowest y).
   An actor with `feet_y` below that number is drawn behind it.
6. `lights`: each visible light source: `xy` (native px), `rgb` (warm lamp ≈
   `[255, 214, 140]`, daylight ≈ `[205, 222, 255]`), `strength` 0–1 (main light 1.0).
7. Make a test shot (section A) and check the review sheet. Tweak `horizon_y`, the occluder
   traces, or light strength until it looks right.

## Why sprites look pasted on

AI pixel-art plates are pseudo-pixel art: about 4–5px "pixels" on no strict grid, with 250k+ colours.
A sprite dropped on top has a different pixel size, its own colours, and no lighting from the
room. Each step below removes one of those mismatches.

## Pipeline (per shot)

1. **Grid-lock.** Box-downscale the plate by `scale` (default 4) to its native size (256×384
   for a 1024×1536 plate). All compositing happens there, then a nearest-neighbour upscale. Plate and
   sprites end up on the same pixel grid.
2. **Palette-lock.** `plate_colours` (64) median-cut from the plate, plus `cast_colours` (20)
   from each actor's sprite, so costume colours the room lacks survive (otherwise James's blue
   shirt turns cream). Every pixel snaps to this palette at the end.
3. **Perspective scale.** Height = `(feet_y − horizon_y) / eye_frac`: a standing adult's eye
   line sits on the horizon. `horizon_y` was measured from card5.
4. **Contact shadow.** A flat ellipse under the feet, darkened ×0.68 and palette-snapped.
5. **Light tint.** 12% pull toward the plate's local mean colour; legs up to 18% darker
   toward the floor; a rim tint on edge pixels facing each `lights` entry, with distance
   falloff; outer outline = own colour ×0.6 (selective outline, "selout").
6. **Occluders.** Foreground objects (`occluders`: ellipse/rect/line/polygon in native px) are
   painted back from the plate in depth order by floor-contact y. An actor whose `feet_y` is
   above an occluder's `depth_y` is drawn behind it.

## Files

- `plates/<plate>.json`: per-plate setup: image, scale, palette sizes, horizon, lights,
  occluders. Done once per blank plate; occluder shapes are rough hand-drawn traces.
- `shots/<name>.json`: `{plate, shots:[{id, label, actors:[...]}]}`. An actor is either
  `{sprite, feet_x, feet_y, flip?}` (native px) or `{cutout, shadow?}`.
- `extract.py` + `poses/<pose>.json`: `{plate, ai_image, region, threshold?, close?, out}`.
  Region in full-res px. Cut = inside region AND differs from plate (after a ±4 px alignment
  check), then median denoise, opening, closing, largest connected shape and hole fill.
  Cut-outs are grid- and palette-locked by compose but not relit; the AI already lit them.

## Limits

- **Sprite actors only stand.** For leaning, sitting or holding things use a cut-out (section C).
- Downscaling a high-res sprite master softens faces a little.
- Occluder traces are rough; tighter polygons, or a painted mask PNG, would be cleaner.

## Cutout
Process

1. Generate in ChatGPT.
   - Upload the blank plate and character's master sprite.
   - Prompt along the lines of: "Add this man leaning his hip against the front-left corner of the desk, hands on its edge. Same pixel-art style and scale as the room. Change nothing else. Keep the exact image size."
   - Ask for 3–4 variations and pick the best pose.
2. Cut him out (new script). A plain difference check won't work alone, because of the drift. Combine three things:
   - A rough outline from you: a loose loop around James, including the desk area he touches. This can be four corners typed into the shot file, or a painted mask image.
   - Changed pixels: inside that outline, keep only pixels that differ clearly from the plate.
   - Clean-up: keep the largest connected shape, fill any holes, and drop stray specks. Fallback for messy cases: rembg, a free local background-removal tool.
3. Save the cut-out as a pose: assets/character-references/James/poses/workshop_lean_desk.png, plus its position in the room. Because it's fixed to that position, it never needs resizing or re-angling.
4. Composite it. The compositor gets a new "cut-out" character type:
   - placed at its saved position, not resized;
   - no added lighting, since the AI already lit it to match;
   - still matched to the room's pixel size and colours;
   - still drawn behind furniture where needed;
   - shadow optional (the AI usually draws one, which gets cut out with him).

One limit: a cut-out pose only fits that room and that spot. Reusing it at another desk, or in a different room, means generating it again.
