# Dial menu — art spec (ticket 06, revised after the exploded master)

Status: **APPROVED**, revised 2026-11-21 (human). Used by 08 (placeholder slices) and 09 (real art).

## 0. Decisions already made (human, 2026-11-21)

- One Dial body for the player: a **closed, short telescopic umbrella**. It's not picked and not shown as an option.
- **One source image.** `assets/hq/dial/dial_exploded_source.png` (1024 × 1536, generated) shows the Dial exploded into four modules. It is pixelised (§1), the background removed, and each module cut into its own PNG. **No assembled image is made and no per-section "opening" strips are drawn.** The menu assembles the four module images in code from anchors (§2.3) and animates them.
- Order of modules from handle to tip: **head (face + studs) → grip (Movement) → lens collar (Lenses) → canopy (Complications).** The face/needle shows charge. The 4 studs **trigger** Complications in combat. They don't hold them.
- The face/studs are **not a section** in the menu. In combat they're the only part shown, because every combat interaction starts there.
- Menu sections: **Movement** (choose a Movement, read the charge, Wind at the intake), **Lenses**, **Complications**.
- **Angle: high 3/4 for the whole Dial** (the render's). Top rims and lips read as squashed ovals; fronts are flat-on.
- **Opening = separating and emerging.** Selecting a section separates the modules (§3). Movement and Lenses are shown as the component **sliding out of the top lip** of its module and hovering above it. Complications are different: the canopy's cut face with its 4 quadrant chambers is already drawn in the master, so it needs no new art. The UI marks the chambers that can take a Complication, and loading plays a small icon dropping into the chosen chamber.
- True pixel grid with integer zoom. The component side list is a **right column**.
- Prompts are written for the **vertical** layout. Both orientations are specced (§3). **09 built vertical** (the default; `layout.orientation` in `data/dial_art.json`). Horizontal stays open if the on-device check asks for it.
- 09 re-tuned the §3.1 numbers to the real sprites (values live in `data/dial_art.json` `sections`): Movement ×2, a 64-px Movement, head lifted (0, −104) so the Movement hovers between head and grip; Lenses ×2, the three 64-px Lenses stacked above the collar lip, head and grip at (−12, −280); Complications ×3.

## 1. Pixel scale and source processing

- **Pixelise first, cut second.** Run the whole exploded sheet through the pixelizer (`tools/pixelizer.html`, or `.claude/skills/event-storyboard/scripts/pixelize.py`) before cutting, so every module shares one grid origin. Choose the cell size so the result's native width is close to 72 px for a module. Measured values replace the targets below (09 stores them in data). Snap to the palette (`data/palette.json`) or a quantised palette, then clean by hand.
- Background removal: the render has a grey vignette. Cut each module out by hand on the native grid (no soft edges, no semi-transparent pixels).
- **Layers are separate transparent PNGs**, each trimmed to its module, with its anchors in data (§2.3). Positions are whole native px.
- Overview: **×2**. Section zoom: **×3 or ×4**, set per section in §3. Integer scales only, nearest filter. Parts **never rotate**; hovering and bobbing move in whole native px.
- Palette (`docs/ui-vision.md` §2, §6): black umbrella fabric on the neutral ramp; fittings in **gunmetal/blued steel**; a cream face. **No brass or gold**, because `calc_gold` is reserved for calc and cash. Ore colour appears only in Lens glass and glows (`ore_*` hexes in `data/palette.json`).
- Horizontal variant: the same layers rotated 90° CCW. A 90° rotation keeps pixels exact.

## 2. Parts

### 2.1 Module layers (cut from the master)

| File (`assets/hq/dial/`) | What | Notes |
|---|---|---|
| `dial_head.png` | Cap with the cream face (no needle), 4 rim studs (unlit), knurled ring | Combat uses it on its own |
| `dial_grip.png` | Grip cylinder with the hatch panel, the ore intake on the right, the wrist strap. **Open top lip** | The hatch panel is decoration. The Movement leaves through the top lip |
| `dial_lens_collar.png` | Steel band with 3 decorative port discs on its front. **Open top lip** | Lenses leave through the top lip, not the front ports |
| `dial_canopy.png` | Furled canopy, strap, ferrule tip, and the **cut face with 4 quadrant chambers** facing up | The cut face is what the Complications section shows |

Small overlays and hand-made pieces:

| File | Native | Notes |
|---|---|---|
| `dial_needle.png` | 6 × 18 | Already exists; the one sprite rotated in code. Pivot on the face centre |
| `dial_stud_lit.png` | 6 × 6 | Overlay on a stud when that chamber is loaded. Studs are baked off in the head |
| `slot_ghost_lens.png` | 64 × 64 | Dithered outline. Marks a Lens slot the Dial's level hasn't unlocked, in the hover row |
| `chamber_blank.png` | 22 × 8 | Hand-made steel cover over a chamber above `capacityMax` |
| `chamber_ring.png` | 22 × 8 | Hand-made bright rim. Pulses on a chamber that can take a Complication |
| `dial_glow.png` | 16 × 16 | Greyscale mask, tinted by ore. Seated Lens glow, and the intake during Wind |

### 2.2 Components

| File (`assets/hq/dial/components/`) | Count | Native | Pivot | Notes |
|---|---|---|---|---|
| `lens_<ore>.png` | 5 (time, physics, life, fate, emotion) | 64 × 64 (fills the collar's inner lip) | centre | Round glass in a steel bezel, facing the viewer, glass tinted with the ore colour |
| `lens_tier_<n>.png` | 5, hand-made | 64 × 64 | centre | 1–5 notches on the bezel, overlaid |
| `movement_<archetype>.png` | 4 (recharge, capacitor, impact, spread) | 4-frame strip, 256 × 64 (each frame fills the grip's inner lip) | centre of frame | Frame 0 = still; frames 1–3 = spin, for Wind. Motifs: recharge = mainspring spiral; capacitor = stacked barrel plates; impact = hammer and escapement; spread = star wheel |
| `movement_tier_<n>.png` | 5, hand-made | 64 × 64 | centre | Tier jewels on the rim |
| `comp_label_<recipeKey>.png` | one per recipe with an icon in `assets/combat/icons/` | 12 × 12 | centre | **No prompt.** A nearest downscale of the 32 px combat icon, redrawn by hand. A seated Complication is its label icon sitting in the chamber, and the icon is what drops in when loading |

A hovering component has a 1-px bob and no shadow (floor shadows are deferred, see ticket 13). A seated Complication sits flat in its chamber. In the side list, components are shown at the section's zoom scale.

### 2.3 Anchors (measured; values in `data/dial_art.json`)

The cut modules are 86 × 78 (head), 120 × 135 (grip with strap), 83 × 70 (collar) and 72 × 153 (canopy). The assembled Dial is about 122 × 313 native. Sizes elsewhere in this spec that assumed a 72-px-wide Dial have been scaled to match.

| Anchor | Where | Used for |
|---|---|---|
| `top_lip` per module (grip, collar, canopy): `centre`, `rx`, `ry`, `clip_y` | The oval opening on the module's top | The slide-out origin, and the clip line (below) |
| `seat` per module (head, grip, collar): `point` | The centre of the module's bottom edge | Assembly: the module's `seat` sits `seat_depth` px inside the next module's `top_lip` centre |
| `face_centre`, `stud[0..3]` | On the head | The needle hub; stud overlays (N, E, S, W = chamber 0–3) |
| `intake_mouth` | On the grip | The Wind tap target and glow |
| `chamber[0..3]` | On the canopy's cut face | Chamber 0–3 clockwise from NW; icon drop target, overlays, taps |
| `hover.lens_offsets[0..2]`, `hover.movement_offset` | Above the collar and grip lips | Where the emerged components hover |

**Assembly rule.** The assembled Dial is the four layers stacked head, grip, collar, canopy with each upper module's bottom overlapping the lower one's top lip by `seat_depth`, which hides the hollow tops. There is no assembled image.

**Emerging rule.** A component that leaves a module is drawn behind that module's front edge while inside it, clipped at the lip's `clip_y` (the lip's centre line). It rises through the opening plane and hovers above. Loading runs the same motion in reverse.

## 3. Layouts and zoom framing

Display area for a zoomed part is the left column, about 240 px wide. The right column (about 120 px) holds the side list. The rects below are native px and are re-measured at 09 from the real sprites.

### 3.1 Vertical

| View | Native rect (approx.) | Scale | Shows |
|---|---|---|---|
| Overview | whole assembled Dial | ×2 | Section labels beside each band; a soft pulse on bands that have a free slot |
| Movement | head + grip | ×3 | Face and needle (charge) with the grip. The Movement hovers above the grip lip, and the intake stays tappable |
| Lenses | collar | ×4 | The collar with its lip. Loaded Lenses hover above, one per unlocked slot, and ghosts mark locked slots |
| Complications | canopy cut face | ×4 | The canopy dropped away from the collar, its 4 chambers facing the viewer |

Exploded offsets (parts that aren't the target dim to alpha 0.35; values are targets, re-tuned at 09):

| Section | Head | Grip | Lens collar | Canopy + tip |
|---|---|---|---|---|
| Movement | 0 | 0 (Movement hovers above) | (−8, +24) | (−8, +40) |
| Lenses | (−12, −40) | (−12, −40) | 0 (Lenses hover above) | (−12, +40) |
| Complications | (−12, −48) | (−12, −48) | (−12, −48) | (0, +40), not dimmed |

The negative x moves floating parts away from the right-hand list.

### 3.2 Horizontal (if chosen at 09)

Rotate the vertical offsets into the new frame. Zoom rects rotate the same way. The overview is tight; re-check the usable width at 09.

## 4. Animation beats

All timings in seconds, stored in data (09). Easing is cubic-out unless stated. With reduced motion, every beat becomes a 0.1 s crossfade and hovering stops.

1. **Open:** the assembled Dial rises from the bottom (0.25). Then the needle sweeps from minimum to the current charge (0.4).
2. **Zoom in** (tap a section band): the modules split by 4 native px (0.12). Then the camera pans and scales to the section rect while the other modules drift to their exploded offsets and dim (0.35). The right list slides in (0.25), items staggered 0.04 apart.
3. **Section opens** (as the zoom lands):
   - Movement: the seated Movement slides up out of the grip's top lip (0.3) and hovers.
   - Lenses: each loaded Lens slides up out of the collar's top lip, staggered 0.05 left to right (0.3), and hovers. Ghost slots fade in for locked slots.
   - Complications: the canopy drops 40 px away from the collar (0.3, ease in-out), showing the cut face. Chambers that can take a Complication pulse (`chamber_ring`). Loaded chambers show their label icon; blank covers show on chambers above `capacityMax`.
4. **Hover:** whole-pixel ±1 bob on every hovering component (about 1.2 s period, phases offset per component).
5. **Info tag** (tap a list item, a hovering part or a loaded chamber): the existing code-built tag panel (`MapCardStyle`), scaling 0.8 → 1 and fading in (0.12). It has no custom art.
6. **Load** (drag to a socket, or Fit): the component lifts and travels in an arc to the section. Lens or Movement: it descends into the lip until clipped, then re-emerges to hover (0.25), with a glow on the lip (0.2, ore colour for a Lens). Complication: its label icon drops into the chosen chamber (0.25), the chamber flashes for 2 frames, and the matching face stud lights.
7. **Swap** (drop on a filled socket): the old component pops out 8 px and floats back to its list row (0.25). The incoming one starts 0.08 later.
8. **Unload** (drag a part off the device): when released, it floats to its list row (0.2). The socket shows empty.
9. **Wind** (Movement section, tap the intake; the ore choice comes first when 2+ Lenses are loaded): the intake glows in the paid ore's colour (0.15). The Movement plays its spin strip (about 8 fps, 0.5). The needle sweeps up to the new charge (0.4).
10. **Back:** the list slides out (0.2). Hovering components slide back down into their lips and the canopy rises (0.3). The camera zooms out and the modules drift home (0.35). Then the modules snap shut, closing the 4-px split with a 1-px overshoot (0.1).

## 5. Generation prompts

**Master (done).** The exploded master is saved at `assets/hq/dial/dial_exploded_source.png`. It was made from the prompt below, with no reference image. Re-run it only if the master is rejected.

> A short collapsed telescopic pocket umbrella, exploded into its four modules floating apart in a vertical line on one centre axis, with a wide gap of empty space between each. From top to bottom: (1) the head: a steel cap with a cream hand-less watch face, four small steel studs at north, east, south and west on its rim, and a knurled ring; (2) the grip: a thick cylinder with a hatch panel on its front, a funnel-shaped ore intake on its right and a braided wrist strap, its open top lip visible as an oval; (3) the lens collar: a steel band with three round ports in a row on its front, its open top lip visible as an oval; (4) the canopy and tip: furled black fabric with a strap and steel ferrule, its top end cut flat so you look down onto an oval cross-section of four quadrant chambers divided by a cross of steel walls. Every module is fully drawn.

Fixed tail appended to every prompt below (ART-BIBLE §5):

> pixel art, genuine pixel grid with visible dithering, no vector or cel-shaded linework, no smooth anti-aliasing or gradients. Camera angle: high three-quarter view, about 35 degrees above; top surfaces read as slightly squashed ovals, front surfaces face the viewer flat-on; keep this exact angle. Palette: grounded, realistic London colour; black umbrella fabric, gunmetal and blued-steel fittings, a cream enamel face. No brass, no gold, no neon, no fantasy-saturated colour. Lighting: single soft key light from the upper left, hard-edged pixel shadows. Background: transparent. Style reference (technique only): Backbone, NORCO, The Last Night, Eastward.

Each prompt below attaches the **exploded master** (not a new assembled image) so identity and materials carry over. Every output is re-gridded through the pixelizer and cleaned by hand. Hand-made assets (`dial_glow`, `lens_tier_<n>`, `movement_tier_<n>`, `comp_label_<recipeKey>`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_stud_lit`) have no prompt.

**P1 — Lenses** → `lens_time`, `lens_physics`, `lens_life`, `lens_fate`, `lens_emotion`
> Attach: the exploded master. A sprite sheet of five 12x12 round lenses in a row, facing the viewer, each a disc of tinted glass in a thin gunmetal bezel, with a small specular highlight upper left. Glass tints in order: slate blue #4d78a8, rust orange #b8562f, moss green #5a8f4f, muted violet #7a5a9e, dusty rose #b85a82. Identical bezels; only the glass colour differs. Transparent background, clear space between them.

**P2 — Movements** (one prompt per archetype, run P2a first and attach it to b–d) → `movement_recharge`, `movement_capacitor`, `movement_impact`, `movement_spread`
> Attach: the exploded master (and P2a for b–d). A 4-frame horizontal sprite strip, 96x24 total, each frame a 24x24 circular clockwork watch movement in gunmetal and blued steel with tiny jewel bearings, seen from the same high angle as it would sit in the grip's open top. Frame 1 is still; frames 2–4 show its wheels turning a little further each frame, for a looping spin. Consistent identity across all frames. Motif: [a] a coiled mainspring spiral in the centre / [b] stacked barrel plates like a capacitor / [c] a heavy hammer striking an escapement / [d] a many-pointed star wheel.

**P3 — bench backdrop (DEFERRED, ticket 13)** → `dial_bench.png`
> Opaque, edge to edge, 195x422: a dark oxblood leather watchmaker's mat on a workbench, seen from the same high angle, a faint stitched grid, one or two tiny tool marks, a soft vignette made of dithering. No objects on it. Background: opaque (replaces the transparent tail line).

**P4 — floor shadows (DEFERRED, ticket 13)** → `float_shadow_s`, `float_shadow_m`
> A 12x4 and a 24x6 dithered dark shadow ellipse, side by side, transparent background, clear space between them.

## 6. Not in this spec

- Removing the six hafts from data, save state and the seed screen: tickets 11–12.
- The combat face/studs view uses `dial_head`, `dial_needle` and the stud overlay. Its layout belongs to the combat tickets.
- Retired by the revision: `dial_grip_open`, `dial_port_iris`, `dial_port_plug`, `dial_canopy` cut-face redraw, `comp_cartridge`, the 4-frame hatch and iris strips, `dial_device_base.png` as a prompt reference.

## Comments

- 2026-11-21 — Human signed off the original spec.
- 2026-11-21 — Revised: one exploded master, cut into module layers; components emerge from the top lips; Complications show the canopy cut face and a dropping icon; the pixelizer cleans the sheet first.
