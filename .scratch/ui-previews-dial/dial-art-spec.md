# Dial menu — art spec (ticket 06)

Status: **APPROVED** (human sign-off 2026-11-21). Used by 07/08 (placeholder slices) and 09 (real art).

## 0. Decisions already made (human, 2026-11-21)

- One Dial body for the player: a **closed umbrella**. It's not picked and not shown as an option.
- Order of parts from handle to tip: **face + studs → Movement → Lens(es) → Complications** → ferrule.
- The face/needle shows charge. The 4 studs **trigger** Complications in combat. They don't hold them.
- The face/studs are **not a section** in the Dial menu. In combat they're the only part shown, because every combat interaction starts there.
- Menu sections: **Movement** (choose a Movement, read the charge, Wind), **Lenses**, **Complications**. Wind happens at the Movement.
- **Angle: high 3/4 for the whole Dial.** The camera sits about 35° above, looking down from the handle end, like the current art. The handle's end face reads as a slightly squashed oval; the body below is drawn as a straight vertical. Every view uses this angle, including the Complications cross-section.
- **Complications live inside the canopy.** Selecting them drops the canopy away from the lens collar. That shows its top cut face, a cross-section with **4 quadrant chambers** (like a revolver cylinder), seen from the same 3/4 angle.
- **Section-open animations:** Movement, the grip hatch swings open. Lenses, the port shutters iris open. Complications, the canopy drops to show the chambers. All reverse on Back.
- True pixel grid with integer zoom. The component side list is a **right column**.
- Prompts are written for the **vertical** layout. Both orientations are specced (§3). The orientation choice is made at 09.

## 1. Pixel scale and canvas

- Device master canvas: **72 × 352 native**, vertical (handle at the top, tip at the bottom). Every device layer is a **full-canvas transparent PNG** in this one coordinate space, so the layers line up with no per-layer offset. The anchors in §2 are native px, origin top-left.
- Overview: **×2** (144 × 704 display). Section zoom: **×3 or ×4**, set per section in §3. Integer scales only, nearest filter. Parts **never rotate** by a non-90° angle; floating and bobbing move in whole native px.
- Angle (§0): every top surface (end face, collar lips, the canopy's cut face) is an oval squashed to about 0.8 of its width, and every front surface is drawn flat-on. Ovals keep the same squash everywhere.
- Horizontal variant: the same layers rotated 90° CCW (handle on the left) to 352 × 72, overview at ×1. A 90° rotation keeps pixels exact, so no regeneration is needed. In that view the 3/4 tilt reads as the camera being off to the left, which is acceptable.
- Palette (`docs/ui-vision.md` §2, §6): black umbrella fabric on the neutral ramp; fittings in **gunmetal/blued steel**; a cream face (as in the current art). **No brass or gold**, because `calc_gold` is reserved for calc and cash. Ore colour appears only in Lens glass and in glows (`ore_*` hexes in `data/palette.json`).
- The anchors below are targets. After cleanup, 09 measures the real sprites and stores the anchors in data.

## 2. Parts

### 2.1 Device layers (72 × 352 canvas)

| File (`assets/hq/dial/`) | What | Native extent | Anchors |
|---|---|---|---|
| `dial_head.png` | Round cap with its end face as a cream oval (no needle) and a knurled collar. Combat also uses it on its own. | y 0–64 | face centre (36,26), face oval 32 × 26 |
| `dial_needle.png` | Needle only, own small canvas 6 × 18, drawn already foreshortened for the oval | — | hub (3,15) → sits on the face centre; sweep −60°…120° as now (rotates in code, the one exception, as today) |
| `dial_stud_off.png` / `dial_stud_lit.png` | One stud, own canvas 6 × 6 | — | on the oval rim: N (36,10), E (54,26), S (36,42), W (18,26) = Complication chamber 0–3; lit = that chamber is loaded |
| `dial_grip.png` | Handle grip with a **closed** Movement hatch facing the viewer, a wrist strap, and an ore intake on the side | y 64–132 | Movement seat centre (36,98), seat 24 × 24; intake mouth (56,96) |
| `dial_grip_open.png` | **4-frame strip** (288 × 68; each frame is the grip, y 64–132): frame 0 closed, frame 3 hatch fully open on its left hinge, showing an empty Movement cavity | — | same as above |
| `dial_lens_collar.png` | Steel collar where the canopy starts, with 3 lens ports on its front; the top lip shows as an oval | y 132–168, x 6–66 | port centres (21,150), (36,150), (51,150); port 12 × 12 |
| `dial_port_iris.png` | **4-frame strip** (48 × 12): a steel iris shutter over one port, frame 0 closed, frame 3 open | — | port centre; played on each unlocked port |
| `dial_port_plug.png` | Blanking plug for a Lens port the Dial's level hasn't unlocked yet (`lensSlotsByLevel`), 12 × 12. It never opens. | — | port centre |
| `dial_canopy.png` | Folded canopy **and** its top cut face: an oval cross-section, 56 × 42, holding 4 quadrant chambers. At rest the lens collar hides the cut face. | y 147–304 (cut face y 147–189, centre (36,168)) | chamber centres from the cut-face centre: NW (−13,−9), NE (+13,−9), SE (+13,+9), SW (−13,+9) = chamber 0–3 clockwise from NW; chamber 26 × 19 |
| `dial_chamber_blank.png` | Steel cover for one chamber above `capacityMax`, 26 × 19 (the NW quadrant shape; other quadrants are mirrors) | — | chamber centre |
| `dial_tip.png` | Ferrule / tip | y 304–352 | — (not interactive); moves with the canopy |
| `dial_glow.png` | Greyscale glow mask, 16 × 16, **hand-made**. Tinted by ore in code for a seated Lens and for the intake during Wind | — | centre |

Draw order (back to front): canopy, tip, chamber blanks, lens collar, plugs/irises, grip, head, glows, components, studs, needle. The lens collar is drawn over the canopy so it hides the cut face until the canopy drops.

### 2.2 Components

| File (`assets/hq/dial/components/`) | Count | Native | Pivot | Notes |
|---|---|---|---|---|
| `lens_<ore>.png` | 5 (time, physics, life, fate, emotion) | 12 × 12 | centre | Round glass in a steel bezel, facing the viewer, glass tinted with the ore colour |
| `lens_tier_<n>.png` | 5, **hand-made** | 12 × 12 | centre | 1–5 notches on the bezel, overlaid |
| `movement_<archetype>.png` | 4 (recharge, capacitor, impact, spread) | 4-frame strip, 96 × 24 | centre of frame | Facing the viewer through the hatch. Frame 0 = still; frames 1–3 = spin, for Wind. Motifs: recharge = mainspring spiral; capacitor = stacked barrel plates; impact = hammer and escapement; spread = star wheel |
| `movement_tier_<n>.png` | 5, **hand-made** | 24 × 24 | centre | Tier jewels on the rim |
| `comp_cartridge.png` | 1 | 16 × 13 | centre | A cartridge seen end-on from the 3/4 angle: an oval steel cap with a 10 × 10 label window, a sliver of glass body below it |
| `comp_label_<recipeKey>.png` | one per recipe with an icon in `assets/combat/icons/` | 10 × 10 | — | **No prompt.** A nearest downscale of the 32px combat icon, redrawn by hand |
| `float_shadow_s.png` / `_m.png` | 2 | 12 × 4 / 24 × 6 | centre | Dithered ellipse under a floating component |

Seated vs floating: **one sprite for both.** A floating component gets the shadow below it, a 2-native-px lift and a 1-px bob. A seated one has no shadow and sits on its anchor. In the side list, components are shown at the section's zoom scale.

### 2.3 Chrome

| File | Native | Notes |
|---|---|---|
| `assets/hq/dial/dial_tag.png` | 24 × 24, 9-slice margins 8 | The info bubble as a **cream paper tag** (dark text on cream, `ui-vision` §11), with a punched hole |
| `assets/hq/dial/dial_tag_string.png` | 4 × 16 tile | Tag string from the tag to the part it describes |
| `assets/hq/dial/dial_bench.png` | 195 × 422 (×2 full screen), opaque | Dark leather watchmaker's mat, faint stitched grid, seen from the same high angle. The backdrop for the menu |

## 3. Layouts and zoom framing

Display area for a zoomed part is the left column, about 240 px wide. The right column (about 120 px) holds the side list. The section rects below are native px, measured **after** the exploded offsets are applied.

### 3.1 Vertical

| View | Native rect (x, y, w, h) | Scale | Display |
|---|---|---|---|
| Overview | 0, 0, 72, 352 | ×2 | 144 × 704, centred; section labels beside each band |
| Movement | 0, 0, 72, 140 | ×3 | 216 × 420. Face + grip, so the charge is readable |
| Lenses | 6, 120, 60, 60 | ×4 | 240 × 240 |
| Complications | 6, 178, 60, 60 | ×4 | 240 × 240. The cut face, after the canopy has dropped |

Exploded offsets (native px from the rest position; parts that aren't the target dim to alpha 0.35):

| Section | Head | Grip | Lens collar | Canopy + tip |
|---|---|---|---|---|
| Movement | 0 | 0, hatch strip plays | (−8, +24) | (−8, +40) |
| Lenses | (−12, −40) | (−12, −40) | 0, irises play | (−12, +40) |
| Complications | (−12, −48) | (−12, −48) | (−12, −48) | (0, +40), **not dimmed**: its cut face is the target |

The negative x moves floating parts away from the right-hand list.

### 3.2 Horizontal (if chosen at 09)

Rotate the vertical offsets into the new frame (vertical y becomes x; vertical x becomes y, so floating parts move up, away from the list area). Zoom rects rotate the same way. The overview is 352 × 72 at ×1, so the left column holds about 70 native px across. Lenses ×4 and Complications ×4 fit; Movement drops to ×3. The overview is tight at 352 of 358 usable px.

## 4. Animation beats

All timings in seconds, stored in data (09). Easing is cubic-out unless stated. With reduced motion, every beat becomes a 0.1 s crossfade, and the open strips jump to their last frame.

1. **Open:** the device rises from the bottom (0.25). Then the needle sweeps from minimum to the current charge (0.4).
2. **Zoom in** (tap a section band): the joints split by 4 native px (0.12). Then the camera pans and scales to the section rect while the other parts drift to their exploded offsets and dim (0.35). The right list slides in (0.25), items staggered 0.04 apart.
3. **Section opens** (as the zoom lands):
   - Movement: the hatch strip plays frames 0→3 (4 frames, 0.2).
   - Lenses: each unlocked port's iris plays 0→3 (0.2), staggered 0.05 left to right. Plugged ports stay shut.
   - Complications: the canopy + tip drop 40 px away from the lens collar (0.3, ease in-out), showing the cut face and its chambers. Then the loaded cartridges settle 1 px into their chambers.
4. **Info tag** (tap a list item or a seated part): the tag swings in on its string from the item, scaling 0.8 → 1 and fading in (0.12), with a 1-px settle.
5. **Load** (drag to a socket, or Fit): the component lifts with a shadow, then travels in an arc to the socket (0.25). It seats with a 1-px overshoot and a 2-frame flash on the socket lip. Lens: the port glows in its ore colour (0.2). Complication: the cartridge drops into its chamber cap-up, and the matching face stud lights. Movement: the seat accepts it and the gears tick once.
6. **Swap** (drop on a filled socket): the old part pops out 8 px and floats back to its list row (0.25). The incoming part starts 0.08 later.
7. **Unload** (drag a seated part off the device): when released, it floats to its list row (0.2). The socket shows its empty lip.
8. **Wind** (Movement section, tap the intake; the ore choice comes first when 2+ Lenses are loaded): the intake glows in the paid ore's colour (0.15). The Movement plays its spin strip (about 8 fps, 0.5). The needle sweeps up to the new charge (0.4).
9. **Back:** the list slides out (0.2). The section closes by playing its open beat in reverse (hatch shuts, irises close, canopy rises). The camera zooms out and the parts drift home (0.35). Then the parts snap shut, closing the 4-px split with a 1-px overshoot (0.1). New components show seated.

## 5. Generation prompts

The workflow follows ART-BIBLE §4 (never re-prompt per piece): generate **one canonical assembled umbrella**, then build every device sheet as an *edit of it*, attaching it as a reference. Every output is then re-gridded to native size, cleaned and cut into layers by hand (§2 files). Each prompt yields the files listed after it. Hand-made assets (`dial_glow`, tier overlays, comp labels) have no prompt.

Fixed tail appended to every prompt below (ART-BIBLE §5):

> pixel art, genuine pixel grid with visible dithering, no vector or cel-shaded linework, no smooth anti-aliasing or gradients. Camera angle: high three-quarter view, about 35 degrees above, looking down from the handle end; top surfaces read as slightly squashed ovals, front surfaces face the viewer flat-on; keep this exact angle. Palette: grounded, realistic London colour; black umbrella fabric, gunmetal and blued-steel fittings, a cream enamel face. No brass, no gold, no neon, no fantasy-saturated colour. Lighting: single soft key light from the upper left, hard-edged pixel shadows. Background: transparent. Style reference (technique only): Backbone, NORCO, The Last Night, Eastward.

**P1 — master assembled Dial** → reference for everything; source of `dial_head`, `dial_grip`, `dial_lens_collar`, `dial_canopy` (outer part), `dial_tip`
> Attach: `assets/hq/dial/dial_device_base.png` (reference for the handle head and the camera angle).
> A closed black gentleman's umbrella standing perfectly upright, handle at the top, tip at the bottom, filling a tall narrow 72x352 native canvas (the umbrella is about 64 px wide at the head and narrows toward the tip). Seen from above like the attached image: the round end of the handle faces up toward the camera, showing a cream watch face with no hands as an oval, with four small steel studs at north, east, south and west on its rim, and a knurled steel collar below. Below the collar, the handle grip carries a small rectangular steel hatch on its front, closed, with a tiny hinge on its left and a visible seam, plus a small funnel-shaped intake port on the right side of the grip, and a braided wrist strap hanging from the right. Where the canopy begins there is a wide steel collar band with three round lens ports in a row on its front, each closed by a small steel iris shutter. Directly below that collar, a fine engraved seam ring runs around the canopy. The folded canopy is plain and ends in a steel ferrule tip. Precise watchmaker craftsmanship, an ordinary London umbrella that is secretly an instrument. One object, no other items.

**P2 — hatch opening** → `dial_grip_open.png`
> Attach: P1 result. A 4-frame horizontal sprite strip of only the handle grip from the attached image, same angle, consistent identity across all frames. Frame 1: the steel hatch closed. Frames 2–3: the hatch swinging open on its left hinge. Frame 4: fully open, showing an empty circular cavity about 24 px across with a steel mounting ring and a centre spindle, waiting for a clockwork movement. Nothing else changes between frames.

**P3 — lens iris** → `dial_port_iris.png`
> Attach: P1 result. A 4-frame horizontal sprite strip, 48x12, of one 12x12 round lens port from the attached collar, facing the viewer: a steel iris shutter of thin overlapping leaves, closed in frame 1, opening through frames 2–3, fully open in frame 4 to show an empty dark socket with a steel rim. Consistent identity across all frames.

**P4 — canopy cross-section** → `dial_canopy.png` (cut face)
> Attach: P1 result. The folded canopy and tip from the attached image, without the handle or lens collar, at the same angle. The top of the canopy is cut cleanly at the seam ring, so from this high angle you look down onto a flat oval cross-section, about 56x42. It's a heavy steel insert divided by a cross of steel walls into four quadrant chambers, like a revolver cylinder, each chamber empty and dark inside with a bevelled rim. The folded fabric wraps around the insert's outer edge.

**P5 — small device parts sheet** → `dial_stud_off`, `dial_stud_lit`, `dial_port_plug`, `dial_chamber_blank`, `comp_cartridge`, `float_shadow_s`, `float_shadow_m`
> Attach: P1 and P4 results (match materials and angle). A sprite sheet of small separate items in a row with clear space between them, each on a transparent background: (1) a 6x6 steel stud, unlit; (2) the same stud lit with a soft warm-white glow, not gold; (3) a 12x12 round steel blanking plug with a slot screw, facing the viewer; (4) a 26x19 quadrant-shaped steel cover plate that fits one chamber of the attached cross-section, with a small rivet; (5) a 16x13 cartridge seen end-on from above: an oval steel cap with a blank square label window and a sliver of glass body below; (6) a 12x4 dithered dark shadow ellipse; (7) a 24x6 dithered dark shadow ellipse.

**P6 — Lenses** → `lens_time`, `lens_physics`, `lens_life`, `lens_fate`, `lens_emotion`
> Attach: P1 result. A sprite sheet of five 12x12 round lenses in a row, facing the viewer, each a disc of tinted glass in a thin gunmetal bezel, with a small specular highlight upper left. Glass tints in order: slate blue #4d78a8, rust orange #b8562f, moss green #5a8f4f, muted violet #7a5a9e, dusty rose #b85a82. Identical bezels; only the glass colour differs. Transparent background, clear space between them.

**P7 — Movements** (one prompt per archetype, run P7a first and attach it to b–d) → `movement_recharge`, `movement_capacitor`, `movement_impact`, `movement_spread`
> Attach: P2 result (and P7a for b–d). A 4-frame horizontal sprite strip, 96x24 total, each frame a 24x24 circular clockwork watch movement in gunmetal and blued steel with tiny jewel bearings, facing the viewer as it would sit in the open hatch. Frame 1 is still; frames 2–4 show its wheels turning a little further each frame, for a looping spin. Consistent identity across all frames. Motif: [a] a coiled mainspring spiral in the centre / [b] stacked barrel plates like a capacitor / [c] a heavy hammer striking an escapement / [d] a many-pointed star wheel.

**P8 — tag** → `dial_tag`, `dial_tag_string`
> A small cream paper luggage tag, 24x24, slightly worn edges, a punched hole with a steel eyelet on the left, plain blank face for text; plus a separate 4x16 vertical tile of thin twine. Flat, front-facing, for 9-slice stretching: the edges are uniform except the hole corner. (Ignore the camera-angle line of the tail for this one.)

**P9 — bench backdrop** → `dial_bench.png`
> Opaque, edge to edge, 195x422: a dark oxblood leather watchmaker's mat on a workbench, seen from the same high angle, a faint stitched grid, one or two tiny tool marks, a soft vignette made of dithering. No objects on it. Background: opaque (replaces the transparent tail line).

## 6. Not in this spec

- Removing the six hafts from data, save state and the seed screen: tickets 11–12.
- The combat face/studs view uses `dial_head`, `dial_needle` and the studs. Its layout belongs to the combat tickets.

## Comments

- 2026-11-21 — Human signed off.
