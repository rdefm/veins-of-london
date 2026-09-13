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

**Mood (amended 2026-09-09, `docs/ui-vision.md` §2 — supersedes this
paragraph and the lighting-rule sentence below it):** grounded, realistic
London colour — vivid where the real city is vivid (brick red, bus/
pillar-box red, shopfront paint, park green), restrained where it
naturally is. Not neon, not fantasy-saturated, not dark-noir — but also
not "mundane and unremarkable" or locked to grey/overcast; that framing
overcorrected into flatness and is retired. `docs/ui-vision.md` §2 is
canonical for mood; this section stays canonical for grid/technique/
pipeline below.

**Lighting: no longer a fixed rule.** Per-plate lighting and weather/
time-of-day are a creative choice made when that plate is briefed, not a
single locked "top-left key light, every plate, always" condition. (The
three original reference images that motivated the old rule all happened
to share top-left key light — that's a fine default to reach for, just no
longer mandatory.)

## 2. Reference palette

`data/palette.json` — **43 colours**, swatch at `data/palette_swatch.png`
(regenerate with `python3 tools/make_palette_swatch.py` after any edit to
the JSON). Generated combat art is **not** required to quantise to this
list. The palette
still backs `combat_visuals.json`'s backdrop `fallbackColor` (resolved via
`GameData.PALETTE`) and stands as the reference swatch for the mood
direction below when writing generation prompts.

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
| Event thumbnail | 358 × 170 |
| VN image frame | 390 × 544 |
| VN text frame | 358 × 236 |

Each row is the exact pixel dimensions a prepared asset is delivered at —
content is centred on that canvas, cropped if larger, padded if smaller.
There is no other alignment rule (no floor/feet-anchoring) — a later
ticket wanting baseline alignment instead of centring makes that change
deliberately, not by working around it per-asset.

The VN rows describe the fixed 390×844 baseline layout, not required source
image dimensions. The image is centred and aspect-covered into the upper
frame; overflow is cropped. Keep faces, hands, and story-critical detail near
the centre because viewport height and safe-area insets can change the visible
top/bottom crop. The opaque lower text frame is separate: never place required
visual information as though it will remain visible behind it.

## 4. Generation discipline

No automated pipeline tool — every generated asset is re-gridded to its
true native pixel size, cleaned of anti-aliased fringe, and cropped/padded
to canvas by hand before it lands under `assets/`.

**Never re-prompt a character per frame** (vision §6 step 3) — generate one
canonical sprite, then edit that image for every other pose, or generate an
entire keypose strip in a single generation. Re-prompting per frame is how
you get a character whose face changes mid-punch — this is a
generation-time discipline, not something tooling can enforce.

`data/combat_visuals.json` (introduced in ticket 08) maps enemy template
key → sheet path + animation names; it does not describe how the sheet
files themselves are produced.

## 5. Generation prompt template

Fill the bracketed fields per subject/plate. Keep every field even when
terse — the point is a reproducible starting point, not a one-off phrase
someone has to reverse-engineer in six months.

```
[SUBJECT], pixel art, [NATIVE RESOLUTION, e.g. 32x52] native grid upscaled
for export, genuine pixel grid with visible dithering — no vector or
cel-shaded linework, no smooth anti-aliasing or gradients.
Lighting: [pick per plate — a single key light, hard-edged pixel shadows;
direction/weather/time-of-day chosen for this plate, not a fixed default].
Palette: grounded, realistic London colour — brick red, shopfront paint,
park green, restrained where the real city is (concrete, pavement, sky).
No neon, no fantasy-saturated colour.
Pose/frame: [e.g. "idle, arms relaxed, weight on back foot" /
"attack wind-up keypose" / "static isometric diorama plate, no
characters"].
Lighting/weather/time-of-day: [pick per plate — no longer a fixed rule,
see §1].
Background: [transparent, for a combatant/effect — solid neutral fill
never partial-alpha gradients, for a plate].
Style reference (technique only, not mood): Backbone, NORCO, The Last
Night, Eastward.
```

Notes:

- For **combatants**, always request a transparent background explicitly —
  image models default to a scene, and clean transparency is much easier
  to prepare by hand than fringe-stripping a gradient-matted background.
- For **backdrop plates**, no fringe-stripping is needed (no alpha channel
  expected) — request an opaque fill edge-to-edge instead.
- For a **keypose strip** (attack wind-up/strike/recover, or an idle
  ping-pong pair), generate all frames in one image as a single
  horizontal strip and say so explicitly in the prompt (`"N-frame
  horizontal sprite sheet, consistent character identity across all
  frames"`) — this is what makes identity hold across frames; see vision
  §6 step 3.
- Every field after `Palette:` is expected to survive unaltered once the
  asset is re-gridded/trimmed to canvas — that cleanup doesn't recolour,
  relight, or repose.

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
