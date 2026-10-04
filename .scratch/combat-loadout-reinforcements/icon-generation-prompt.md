# Prompt for a fresh chat: VEIN item and combat command icons

Create production-ready pixel-art icons for the 14 crafted consumables in VEIN, plus two matching combat command icons: Attack and Leg it.

Read these project sources first:

- `.scratch/combat-loadout-reinforcements/spec.md` — the item-icon requirement and new combat dock.
- `docs/ART-BIBLE.md` §§1–5 — pixel-art technique and asset preparation.
- `docs/ui-vision.md` §§2, 5–7 — grounded London colour, physical art versus UI chrome.
- `data/recipes.json` — exact recipe IDs, names, ingredients and descriptions.
- `.scratch/combat-loadout-reinforcements/combat-view-mockup.png` — scale and placement reference. Its icons are illustrative, not finished assets.

## Deliverables

- One transparent PNG per recipe, named by its exact JSON ID: `timePearl`, `enhancementPowder`, `rewind`, `healingSalve`, `blast`, `shield`, `blackHole`, `prophetsBreath`, `beALady`, `pansPrank`, `healingBurst`, `failsafe`, `rejuvenation`, `wormhole`.
- Two transparent PNGs for the combat commands, `attack` and `leg_it`, in the same visual style.
- A nearest-neighbour enlarged contact sheet showing every icon on both the near-white combat dock and the dark Phone content surface, with names outside the icon cells.
- Save final assets in the repo, grouped under `assets/`. Report all paths and any size decision that differs from the proposal below.

## Size and export target

Use a **proposed 32 × 32 native pixel canvas** for each icon, with a crisp 1-pixel grid and roughly 2 pixels of transparent clearance at its edges. Keep the main silhouette large enough to read at **32 × 32 logical pixels** in a **390 × 844** portrait UI. The surrounding command row supplies the touch target; the icon itself is not a 48-pixel button. The current spec does not lock an icon canvas size, so check the consuming UI before final export and report any needed adjustment.

Export individual RGBA PNGs at native size. If generating at a larger resolution, re-grid and clean each icon to the native canvas; do not deliver a merely downscaled, blurry image. No soft alpha fringe, anti-aliasing, smooth gradients, lettering, numbers, tier labels, borders, button backgrounds or baked shadows. Preview enlarged only with nearest-neighbour scaling. Check each icon at actual 1× size on both surfaces.

## Shared art direction

Genuine full-frame pixel art: deliberate clusters, hard-edged highlights and shadows, restrained dithering, coherent outline weight. Contemporary indie technique consistent with the project's combat sprites. Grounded, recognisable physical objects made with calc; London colour can be vivid where real materials are vivid, but avoid neon, generic fantasy runes and glowing spellbook symbols. Use `data/palette.json` as a mood reference, not a mandatory quantisation table. The five ore colours may provide small distinguishing accents; physical material and silhouette should do most of the work.

Each item must be identifiable from shape before colour. Use different containers and profiles; do not make fourteen near-identical bottles. These are the object's inventory icons, not spell effects or the old text glyphs. Keep tiers out of the artwork: the same icon serves every tier, with the UI showing `T1`–`T5` separately.

## Visual briefs

| ID | Suggested physical silhouette |
|---|---|
| `timePearl` | Single pale pearl in a shallow, dark brass setting; tiny cool-blue glint. |
| `enhancementPowder` | Folded paper powder sachet, torn corner, a trace of green powder. |
| `rewind` | Compact hourglass with dark frame and blue-grey grains; its hourglass form is established in `data/recipes.json`. |
| `healingSalve` | Squat screw-top salve tin with a muted green smear at the open edge. |
| `blast` | Short, blunt pressure capsule with copper casing and a physics-orange seam. |
| `shield` | Thick round metal token or compact guard plate, seen at a slight angle; distinct from the Blast capsule. |
| `blackHole` | Small dinner-plate-like dark disc with an off-centre recessed core and restrained copper edge. |
| `prophetsBreath` | Tall narrow inhaler or stoppered breath vial, with a wisp suggested in a few hard pixels. |
| `beALady` | Fate-purple wrapped packet with a small off-centre seal; avoid literal clover glyph art. |
| `pansPrank` | Pink-tinted glass ampoule with a crooked stopper; no face glyph. |
| `healingBurst` | Bright green, fast-use glass ampoule with a metal crimp; distinguish clearly from salve and Prophet's Breath. |
| `failsafe` | Sturdy red-and-blue sealed capsule with a prominent mechanical latch; more substantial than Rewind. |
| `rejuvenation` | Refined small jar with a pale floral-toned contents and a clean lid; understated luxury, no magic flower glyph. |
| `wormhole` | Paired offset metal rings or a hinged folding device, with a narrow dark aperture between them. |
| `attack` | A forward-thrust clenched fist with a jacket cuff, strong diagonal silhouette. The player's attack is unarmed under this spec; no swords, guns or crowbars. |
| `leg_it` | Scuffed running trainer angled forward with two or three detached motion pixels. Readable as escape, not another attack pose. |

Treat these silhouettes as a starting brief. If one clashes with established item art or its recipe description, follow the source and explain the change. Keep the command icons stylistically matched to the items while allowing the UI to apply its action colour separately.

## Review before delivery

Inspect every final PNG at 1×. Verify transparent corners, no fringe, distinct silhouettes, consistent scale, and legibility on light and dark surfaces. Check that Attack cannot be mistaken for a weapon and Leg it cannot be mistaken for a consumable. Show the contact sheet for visual review, then report the final asset list and any unresolved visual choices.
