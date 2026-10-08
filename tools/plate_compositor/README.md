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

All coordinates are **native px** = full-res px ÷ `scale` (5 for the workshop). Read them off
the full-res plate in any image editor (cursor position), then divide by 5.

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
   - nobody overlaps furniture they should be behind (if they do, add an occluder, step B5);
   - the shadow sits under the feet.
   To fix one, nudge `feet_x`/`feet_y` by 2–5 px and re-run.
6. When happy, copy the shot PNG to `assets/events/<event_id>/<event_id>_card<N>.png`.

### B. Set up a new blank plate (once per room)

1. Put the blank plate (no characters) in `assets/reference-plates/`.
2. Copy `plates/james_workshop.json` to `plates/<plate_name>.json` and set `image`.
3. `scale`: the plate's apparent pixel size in full-res px. Zoom in and count how wide one
   "pixel" block is; 5 is typical for ChatGPT pixel art at ~937 px wide.
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

AI pixel-art plates are pseudo-pixel art: about 5px "pixels" on no strict grid, with 250k+ colours.
A sprite dropped on top has a different pixel size, its own colours, and no lighting from the
room. Each step below removes one of those mismatches.

## Pipeline (per shot)

1. **Grid-lock.** Box-downscale the plate by `scale` (5) to its native size (187×335 for
   the workshop). All compositing happens there, then a nearest-neighbour upscale. Plate and
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
- `shots/<name>.json`: `{plate, shots:[{id, label, actors:[{sprite, feet_x, feet_y, flip?}]}]}`.
  Coordinates are native px (full-res ÷ scale).

## Limits

- **Pose comes from the sprite.** Standing figures only: no leaning, sitting or holding
  anything in the room. That needs new pose art (see below).
- Downscaling a high-res sprite master softens faces a little.
- Occluder traces are rough; tighter polygons, or a painted mask PNG, would be cleaner.

## Next: dynamic poses (planned, not built)

Masked AI inpainting plus a paste-back step:

1. In ChatGPT (or SD/Flux inpaint), brush a mask over the character area on the blank plate,
   attach the sprite reference, and prompt the pose ("leaning on the desk").
2. The AI tends to drift the *whole* image, so a script keeps only the masked region from the AI
   output and composites it onto the untouched plate. The background stays pixel-identical.
3. Run the result through grid-lock and palette-lock (steps 1–2 above).
