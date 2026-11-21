# Dial menu — image prompts (proof pass: one of each)

Source of truth: `dial-art-spec.md` §5. This file is the pasteable subset for the proof pass. Once the pipeline is proven, the remaining Lenses (physics, life, fate, emotion) and Movements (capacitor, impact, spread) are repeats of P1 and P2.

**For every prompt:** attach `assets/hq/dial/dial_exploded_source.png` where it says "Attach". Append the fixed tail unless the prompt says to ignore it. Pixelise every output (`tools/pixelizer.html`) before using it.

**Fixed tail**

> pixel art, genuine pixel grid with visible dithering, no vector or cel-shaded linework, no smooth anti-aliasing or gradients. Camera angle: high three-quarter view, about 35 degrees above; top surfaces read as slightly squashed ovals, front surfaces face the viewer flat-on; keep this exact angle. Palette: grounded, realistic London colour; black umbrella fabric, gunmetal and blued-steel fittings, a cream enamel face. No brass, no gold, no neon, no fantasy-saturated colour. Lighting: single soft key light from the upper left, hard-edged pixel shadows. Background: transparent. Style reference (technique only): Backbone, NORCO, The Last Night, Eastward.

## P1 — Lens (time) → `lens_time`

> Attach: the exploded master. A single 12x12 round lens facing the viewer: a disc of slate blue (#4d78a8) tinted glass in a thin gunmetal bezel, with a small specular highlight upper left. Transparent background, nothing else in frame.

Later: physics `#b8562f`, life `#5a8f4f`, fate `#7a5a9e`, emotion `#b85a82`. Same prompt, change only the glass colour.

## P2 — Movement (recharge) → `movement_recharge`

> Attach: the exploded master. A 4-frame horizontal sprite strip, 96x24 total, each frame a 24x24 circular clockwork watch movement in gunmetal and blued steel with tiny jewel bearings, seen from the same high angle as it would sit in the open top of the attached grip. Frame 1 is still; frames 2–4 show its wheels turning a little further each frame, for a looping spin. Consistent identity across all frames. Motif: a coiled mainspring spiral in the centre.

Later: capacitor (stacked barrel plates like a capacitor), impact (a heavy hammer striking an escapement), spread (a many-pointed star wheel). Attach the finished recharge strip to each so the style carries over.

## P3 — Tag (DEFERRED — not needed for the proof pass) → `dial_tag`, `dial_tag_string`

Ignore the camera-angle line of the tail for this one.

> A small cream paper luggage tag, 24x24, slightly worn edges, a punched hole with a steel eyelet on the left, plain blank face for text; plus a separate 4x16 vertical tile of thin twine. Flat, front-facing, for 9-slice stretching: the edges are uniform except the hole corner.

## P4 — Bench backdrop (DEFERRED — not needed for the proof pass) → `dial_bench.png`

Replace the tail's "Background: transparent" with opaque.

> Opaque, edge to edge, 195x422: a dark oxblood leather watchmaker's mat on a workbench, seen from the same high angle, a faint stitched grid, one or two tiny tool marks, a soft vignette made of dithering. No objects on it.

## P5 — Floor shadows (DEFERRED — not needed for the proof pass) → `float_shadow_s`, `float_shadow_m`

> A 12x4 and a 24x6 dithered dark shadow ellipse, side by side, transparent background, clear space between them.

## Hand-made (no prompt)

`dial_stud_lit`, `slot_ghost_lens`, `chamber_blank`, `chamber_ring`, `dial_glow`, `lens_tier_<n>`, `movement_tier_<n>`, `comp_label_<recipeKey>`. Specs are in `dial-art-spec.md` §2.1–§2.2.
