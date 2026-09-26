# Combat card frames

`street_sign_frame.png` is the clean, reusable London street-sign frame.
It is a 24 x 24 RGBA PNG at one art pixel per logical pixel, with no baked-in
text, health bar, faction colour, or damage cue.

Render it as a nine-slice with **6 px margins on all four sides**. The fixed
corners and 2 px dark edge stay crisp at the current card sizes: 101 x 68
(collapsed), 129 x 84 (selected), and 129 x 136 (selected with details).
Use nearest-neighbour filtering, lossless import, and no mipmaps. Draw live
content above the frame.

The ground and border match `combat_sign_ground` and `combat_sign_border` in
`data/palette.json`. The source PNG is the pixel master; export without
resampling or alpha matting.

`street_sign_frame_50.png` and `street_sign_frame_20.png` are 32 x 32 RGBA
replacement frames with **12 px nine-slice margins**. Use the 50 variant at
50% HP or less and the 20 variant at 20% HP or less (the 20 variant takes
priority). They keep damage in the fixed corner/edge areas; the 20 variant
has genuinely transparent missing pieces. Render one frame variant at a
time, behind the live card content. A normal transparent overlay cannot
cut holes through the clean frame.
