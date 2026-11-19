# col_a1_hakim_meet — card2 regen (pixel-scale test)

Goal: a card that survives pixelizer cell size 6 (≈170×256 art pixels) with the face intact.
Approach: face larger in frame + chunky uniform pixels + sprite-style simplified features.

## S2 — "You're Des's" (c2) · regen
Attach: col_a1_hakim_meet_card2.png, hakim_reference.png

```
Redraw col_a1_hakim_meet_card2.png (attached) as lower-resolution pixel art, with the camera pushed in closer on Hakim. Hakim must match hakim_reference.png (attached): same face, messy dark curly hair, greying stubble beard, dark green crew-neck jumper; keep the navy apron from the card.

Pixel scale (most important): draw it as if on a 170×256 pixel canvas and enlarge it exactly 6× with nearest-neighbour, so every art pixel is a clean 6×6 block of one colour. All pixels the same size everywhere in the image, the face included: no finer detail on the face than on the jumper or shelves. Limited palette of about 32 colours, no dithering on skin, crisp hard edges, no anti-aliasing, no blur.

Framing: Hakim behind the newsagent counter, seen from just across it at his eye level. Head, shoulders and forearms on the counter fill the middle of the frame; his face is about a quarter of the image width. Keep the card reader, the mug of biros and a child's half-done homework exercise book with a biro in its fold on the counter. Shelves of crisps, tins and bottles behind him, simplified into blocks of colour. The top and bottom 15% may be cropped, so only ceiling and counter front go there.

Face, drawn as a game sprite, not shrunk from a painting: each eye is a dark 2×1 or 2×2 pixel shape with one single light pixel of highlight beside it; eyebrows are one-pixel-thick dark lines; the nose is two or three pixels of shadow; the mouth is a one-pixel line. Make features slightly bigger than life so they read at this size. One flat skin tone plus one shadow tone and one highlight tone.

Expression: awkward, half-apologetic. Brows raised in the middle, a small embarrassed half-smile, head tipped slightly, looking straight at the viewer, as if he has just said something clumsy.

Light: warm overhead shop strip light, cooler fridge glow from screen-right. Grounded London colour, no neon, no fantasy glow. Portrait 2:3, 1024×1536, full-bleed, no border. No text except the existing "EAST LONDON MART" sign, which can be cut off by the closer crop.
```

Ask for 3–4 variations. Test each in tools/pixelizer.html at cell 6 (try ox/oy offset to line the grid up with the blocks) before picking.

### Delta (if pixels come back too fine)
```
Same image, but chunkier: every art pixel must be a 6×6 block, including on the face. Halve the detail on the face so the eyes are 2-pixel dark shapes with one highlight pixel and the brows, nose and mouth are single-pixel lines. Keep everything else identical.
```
