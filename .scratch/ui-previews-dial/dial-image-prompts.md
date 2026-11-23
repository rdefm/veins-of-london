# Dial menu — image prompts

Source of truth: `dial-art-spec.md` §5. This file is the pasteable subset for the proof pass. Lenses are done (one sprite, shader-tinted). Remaining: Movements capacitor, impact, spread (P2b–d).

**For every prompt:** attach `assets/hq/dial/dial_exploded_source.png` where it says "Attach". Append the fixed tail unless the prompt says to ignore it. Pixelise every output (`tools/pixelizer.html`) before using it.

**Fixed tail**

> pixel art, genuine pixel grid with visible dithering, no vector or cel-shaded linework, no smooth anti-aliasing or gradients. Camera angle: high three-quarter view, about 35 degrees above; top surfaces read as slightly squashed ovals, front surfaces face the viewer flat-on; keep this exact angle. Palette: grounded, realistic London colour; black umbrella fabric, gunmetal and blued-steel fittings, a cream enamel face. No brass, no gold, no neon, no fantasy-saturated colour. Lighting: single soft key light from the upper left, hard-edged pixel shadows. Background: transparent. Style reference (technique only): Backbone, NORCO, The Last Night, Eastward.

## P1 — Lens → `lens_time` (DONE, no more Lens prompts)

Every ore uses `lens_time.png`; `shaders/lens_tint.gdshader` re-colours the glass per ore from `data/ore_types.json`. No per-ore Lens art.

## P2 — Movement (recharge) → `movement_recharge`

> Attach: the exploded master. A 4-frame horizontal sprite strip, 160x40 total, each frame a 40x40 circular clockwork watch movement in gunmetal and blued steel with tiny jewel bearings, seen from the same high angle as it would sit in the open top of the attached grip. Frame 1 is still; frames 2–4 show its wheels turning a little further each frame, for a looping spin. Consistent identity across all frames. Motif: a coiled mainspring spiral in the centre.

Recharge is done and stays as is.

## P2b–d — Capacitor, Impact, Spread

Attach to each: the exploded master **and** the finished `movement_recharge.png` strip, so materials, pixel density and angle carry over. Run b first; if it lands, attach it to c and d as well.

Shared rules (already in each prompt): same metals and jewel bearings as the recharge strip; every frame stands on the **same small round base plate as the recharge movement**, centred and touching the bottom edge, so it rises out of the grip's lip like recharge does. Taller frames are trial sizes; re-evaluate on device.

### P2b — Capacitor → `movement_capacitor` (trial 64×96 native)

> Attach: the exploded master and the recharge movement strip. A 4-frame horizontal sprite strip, 160x60 total, each frame 40x60. Each frame is a tall, narrow clockwork column in gunmetal and blued steel: four flat mainspring barrels (short toothed drums) stacked on one central arbor, separated by thin blued-steel spacer plates, standing on a small round base plate the same size as the recharge movement, capped by a top bridge with a single jewel bearing. A narrow vertical sight-glass slot down the front shows tightly coiled springs inside. It reads as a compact battery of springs. Same high angle as the recharge movement; the base sits at the bottom centre of every frame. Frame 1 is still; frames 2–4 show the barrels' toothed rims turning a little further each frame, alternate barrels turning in opposite directions, for a looping spin. Consistent identity across all frames.

### P2c — Impact → `movement_impact` (trial 64×80 native)

> Attach: the exploded master and the recharge movement strip. A 4-frame horizontal sprite strip, 160x50 total, each frame 40x50. Each frame is a squat, heavy clockwork drum in gunmetal and blued steel, wider than it is tall and thicker-walled than the recharge movement, standing on a small round base plate the same size as the recharge movement. On its top surface a short steel pivot post carries a striking arm ending in a solid square hammer head, like a clock's chime hammer, poised over a small round steel anvil boss on the drum's top. Same high angle as the recharge movement; the base sits at the bottom centre of every frame. Frame 1: hammer resting on the anvil. Frame 2: hammer lifted a little. Frame 3: hammer raised high. Frame 4: hammer down on the anvil, with two or three single-pixel steel-grey flecks at the strike point. No glow, no sparks of colour. Consistent identity across all frames.

### P2d — Spread → `movement_spread` (trial 64×96 native)

> Attach: the exploded master and the recharge movement strip. A 4-frame horizontal sprite strip, 160x60 total, each frame 40x60. Each frame is a miniature flyball governor in gunmetal and blued steel: a thin vertical spindle rising from a small star-toothed wheel on a round base plate the same size as the recharge movement, topped by a collar with a jewel bearing; two slim arms hinge from the collar, each ending in a polished steel ball, linked by short struts to a sleeve that slides on the spindle. Same high angle as the recharge movement; the base sits at the bottom centre of every frame. Frame 1: still, arms hanging down close against the spindle. Frame 2: spinning, arms swung out about 30 degrees, sleeve slightly raised. Frame 3: arms out about 60 degrees. Frame 4: arms nearly horizontal, fully spread, sleeve at its highest; the balls stay inside the frame. Consistent identity across all frames.

**Code follow-up before these can ship:** `dial_art.json` has one `movement_frame` size and a centre anchor. Taller strips need a per-archetype frame size and a bottom-centre anchor (see ticket 13).

## P3 — Bench backdrop (DEFERRED, ticket 13) → `dial_bench.png`

Replace the tail's "Background: transparent" with opaque.

> Opaque, edge to edge, 195x422: a dark oxblood leather watchmaker's mat on a workbench, seen from the same high angle, a faint stitched grid, one or two tiny tool marks, a soft vignette made of dithering. No objects on it.

## P4 — Floor shadows (DEFERRED, ticket 13) → `float_shadow_s`, `float_shadow_m`

> A 12x4 and a 24x6 dithered dark shadow ellipse, side by side, transparent background, clear space between them.

## Hand-made (no prompt)

`dial_stud_lit`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_glow`, `lens_tier_<n>`, `movement_tier_<n>`, `comp_label_<recipeKey>`. Specs are in `dial-art-spec.md` §2.1–§2.2.
