# ART-BIBLE

**Status:** Canon for the combat pixel-art pipeline. Written by ticket
`07-art-bible-palette-pixelize` per `docs/combat-animation-vision.md` §6/§7.
Where this document and the vision doc disagree, the vision doc wins —
this is the buildable reference derived from it, not a replacement.

**Prose:** contains no player-facing copy. Nothing here is `PROSE-REVIEW:`
material.

---

## 1. Direction (locked, see vision §1)

Full sprite-frame pixel art, contemporary-indie technique only — genuine
pixel grid, limited palette, dithered shading, no vector/cel-shaded
linework, no anti-aliasing survives into the shipped asset. Nearest
technical cousins: **Backbone**, **NORCO**, **The Last Night**, **Eastward**.

Mood: **overcast daylight**, muted/desaturated colour — brick red, weathered
pastel shopfronts, grey sky, damp pavement reflecting sky. Not neon, not
rain, not dark-noir. Deliberately mundane and unremarkable, not atmospheric
— the visual expression of "administrative wonder" (`CONTENT-GUIDE.md` §3),
not a whimsical or colourful register.

**Lighting rule: top-left key light, on every subject, every plate,
always.** All three original reference images use it; keep it so a
character generated in isolation still looks lit by the same sun as the
backdrop it's composited onto.

## 2. Master palette

`data/palette.json` — **42 colours**, swatch at `data/palette_swatch.png`
(regenerate with `python3 tools/make_palette_swatch.py` after any edit to
the JSON). Every generated asset is quantised to exactly this list via
`tools/pixelize.py`; no off-palette pixel ships.

| Group | Count | Role |
|---|---|---|
| `neutral` | 6 | Outline black through warm highlight — general shading ramp, not tied to any one surface |
| `sky` | 6 | Overcast sky gradient + damp pavement reflecting it |
| `brick` | 6 | Brick/masonry reds-browns + timber/mortar |
| `pastel` | 6 | Weathered shopfront pastels — dusty blue, faded teal, muted ochre, dusty pink, sage, tan |
| `clothing` | 4 | Desaturated slate-navy ramp for clothing/fabric |
| `skin` | 5 | Skin tone ramp, deepest shadow to pale highlight |
| `foliage` | 2 | Muted street-tree/planter green |
| `accent` | 2 | Calc (orichalchum) gold — the one warm, slightly-more-saturated note, reserved for calc/currency reads |
| `ore` | 5 | One accent per ore type (`time`/`physics`/`life`/`fate`/`emotion`), pulled slightly more saturated than the environment ramps so effect sheets (ticket 11) stay legible against a muted backdrop without breaking the "no neon" rule |

Full list with hex values is `data/palette.json` — that file, not this
table, is canonical if the two ever drift; re-run the swatch script rather
than hand-editing this table.

## 3. Canvas sizes (vision §6.1)

Native, at the 390×844 logical viewport:

| Asset | Native size |
|---|---|
| Combatant | 64 × 104 |
| Backdrop plate | 390 × 360 |
| Effect frame | 96 × 96 |
| Large effect (`blackHole`) | 160 × 160 |

`tools/pixelize.py --canvas WxH` takes exactly one of these per invocation.
Output is centred on a transparent canvas of that size — source content
larger than the canvas is cropped centred; smaller is padded centred. There
is no other alignment rule (no floor/feet-anchoring) — if a later ticket
needs baseline alignment instead of centring, that's a `pixelize.py` change
to make deliberately, not something to work around per-asset.

## 4. `tools/pixelize.py`

Pure Python 3 stdlib — no Pillow, no install step. PNG codec lives in
`tools/png_io.py` (8-bit RGB/RGBA, non-interlaced only — reject anything
else with a clear error rather than silently mishandling it).

```
python3 tools/pixelize.py <input.png> <output.png> --canvas 64x104
```

Pipeline, in order:

1. **Detect native cell size.** Generated art is usually exported upscaled
   from its true pixel grid (e.g. a genuinely 32×32 sprite exported as a
   512×512 PNG). `detect_cell_size()` scores every candidate block size by
   how close the image is to a flat-colour mosaic at that size (fraction of
   each block occupied by its single most-common exact RGBA value,
   averaged over all blocks) and picks the **largest** candidate that
   clears a 0.9 uniformity threshold. This is robust to a thin ring of
   anti-aliased fringe around the silhouette (it dents a handful of blocks'
   scores slightly, not the whole image's) in a way a naive column-edge
   scan isn't — a single stray fringe pixel doesn't collapse detection to
   cell=1. Override with `--cell N` if a given asset auto-detects wrong.
2. **Downsample nearest.** One representative pixel per detected cell (its
   top-left corner) — never averaged. Averaging is exactly the blur this
   step exists to remove.
3. **Quantise to palette.** Every non-fully-transparent pixel's RGB snaps to
   its nearest colour in `data/palette.json` by squared RGB distance; alpha
   passes through unchanged so the next step can still see it.
4. **Strip anti-aliased fringe.** Alpha is binarized at `--alpha-threshold`
   (default 128): below → fully transparent, at/above → fully opaque. Then
   any opaque pixel with **no** orthogonally-adjacent opaque pixel (a
   4-connectivity check) is dropped too — a lone speck with no opaque
   neighbour is always a fringe artifact, never intentional art.
5. **Trim to canvas.** Centred crop/pad to the exact `--canvas` size.

Self-test (no external test framework, run directly):

```
python3 tools/test_pixelize.py
```

Builds a synthetic upscaled sprite with off-palette colour, blended fringe,
and an isolated speck in memory, runs the full pipeline, and asserts every
stage did its job. Run this after any change to `pixelize.py` or `png_io.py`.

**Never re-prompt a character per frame** (vision §6 step 3) — generate one
canonical sprite, then edit that image for every other pose, or generate an
entire keypose strip in a single generation. This is outside pixelize.py's
job; it's a generation-time discipline the tool can't enforce.

`data/combat_visuals.json` (introduced in ticket 08) maps enemy template
key → sheet path + animation names; `pixelize.py` produces the sheet files
that manifest points at, it does not touch the manifest itself.

## 5. Generation prompt template

Fill the bracketed fields per subject/plate. Keep every field even when
terse — the point is a reproducible starting point, not a one-off phrase
someone has to reverse-engineer in six months.

```
[SUBJECT], pixel art, [NATIVE RESOLUTION, e.g. 32x52] native grid upscaled
for export, genuine pixel grid with visible dithering — no vector or
cel-shaded linework, no smooth anti-aliasing or gradients.
Lighting: single key light from top-left, hard-edged pixel shadows.
Palette: muted/desaturated overcast-daylight — brick red, weathered
pastel, grey sky, damp pavement reflecting sky. No neon, no saturated
colour, no rain.
Pose/frame: [e.g. "idle, arms relaxed, weight on back foot" /
"attack wind-up keypose" / "static isometric diorama plate, no
characters"].
Background: [transparent, for a combatant/effect — solid neutral fill
never partial-alpha gradients, for a plate].
Style reference (technique only, not mood): Backbone, NORCO, The Last
Night, Eastward.
```

Notes:

- For **combatants**, always request a transparent background explicitly —
  image models default to a scene, and `pixelize.py`'s fringe-stripping
  step is much cleaner against clean transparency than against a
  gradient-matted background.
- For **backdrop plates**, there is no fringe-stripping step needed (no
  alpha channel expected) — request an opaque fill edge-to-edge instead.
- For a **keypose strip** (attack wind-up/strike/recover, or an idle
  ping-pong pair), generate all frames in one image as a single
  horizontal strip and say so explicitly in the prompt (`"N-frame
  horizontal sprite sheet, consistent character identity across all
  frames"`) — this is what makes identity hold across frames; see vision
  §6 step 3.
- Every field after `Palette:` is expected to survive `pixelize.py`
  unaltered in *spirit* even though the literal colours won't — the tool
  quantises to `data/palette.json`, it doesn't relight or repose.

## 6. Render/import settings (vision §7 — documented here, applied in ticket 08)

These are **rules to document now, project-settings changes to make in
ticket 08** — noted here so the reasoning isn't re-derived later.

1. **Texture import: Lossless, mipmaps off, filter off, as the folder
   default for every combat-art directory.** `project.godot:38`'s
   `textures/vram_compression/import_etc2_astc=true` applies to
   VRAM-Compressed import mode; block compression visibly artifacts pixel
   art. **Applied in ticket 08** as the project-wide `[importer_defaults]`
   texture preset in `project.godot` (`compress/mode=0` Lossless,
   `mipmaps/generate=false`) rather than a true per-folder default — Godot 4
   has no built-in per-folder import-default mechanism, and combat art is
   the only pixel-art pipeline in this project, so project-wide has the
   same effect in practice. A new combat-art PNG still needs `filter off`
   confirmed on import (no per-CanvasItem `texture_filter` override back to
   Linear) since that's a runtime property, not an import-time one.
2. **`rendering/textures/canvas_textures/default_texture_filter` →
   Nearest.** Default is Linear, which turns crisp pixel art to mud.
   `gl_compatibility` (this project's renderer on desktop and mobile) is
   otherwise fine for this. **Applied in ticket 08** —
   `textures/canvas_textures/default_texture_filter=0` in `project.godot`.
3. **Pick one pixel-snapping rule, project-wide, and never mix it.** At
   `canvas_items` stretch on a modern phone, 1 art pixel ≈ 1 logical pixel
   ≈ 3 device pixels — crisp, but a tweened position lands on a fraction
   and shimmers. Two ways to resolve that, not to be mixed across
   characters and effects:
   - Enable `rendering/2d/snap/snap_2d_transforms_to_pixel` — crunchy,
     authentic, everything snaps to the art grid.
   - Leave it off and allow subpixel positioning throughout — smoother,
     slightly softer.
   **Decided in ticket 08: `snap_2d_transforms_to_pixel`, on** —
   `rendering/2d/snap/snap_2d_transforms_to_pixel=true` in `project.godot`.
   Crunchy/authentic matches §1's "genuine pixel grid" direction and the
   named reference games (Backbone, NORCO, Eastward all snap). Every tween
   added after this ticket (juice layer, transform-based attack motion,
   effect sheets) must agree with it — no subpixel positioning anywhere in
   the combat stage.
