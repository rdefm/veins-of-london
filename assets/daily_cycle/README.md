# London time cycle

Source: user-supplied `morning_to_afternoon.zip` and `afternoon_to_evening.zip`.
Original pixels, colours and square composition preserved, including the supplied
magenta surround. No generated/repainted frames or runtime art layers.

- 28 frames, row-major 7 × 4 atlas, 73px cells, **511 × 292px** texture.
- Morning → Afternoon: frames 0–13, native **73 × 73px**.
- Afternoon → Evening: frames 14–27, native **72 × 72px**; cell padding excluded by region.
- At 390px portrait: centred **365 × 365px** and **360 × 360px** artwork respectively
  (5× integer scaling), fully visible, no crop. Destination label below the artwork;
  the artwork/label group is vertically centred. Width scales down in whole pixels
  on smaller viewports. Phone safe areas remain outside the central artwork.
- Lossless import, mipmaps disabled, explicit nearest filtering.
- Each interstitial lasts **1.75 seconds**, independent of frame count.
- Overnight and Early Rest currently hold the first Morning frame for the same
  duration, labelled with the resulting day/Morning. Final night animation pending.
- Reduced motion holds the destination frame, with identical duration/input blocking.

## Add the final animation

Add `evening_to_morning.zip` here using the same `metadata.json` + `spritesheet.png`
contract. Run `python tools/pack_daily_cycle.py` (Pillow required), then Godot import.
The packer rebuilds `cycle.png` and `data/daily_cycle.json`, appending the new range.
Playback automatically traverses all remaining ranges for Early Rest, compressed
into the same 1.75 seconds. Evening rollover uses only the final range.
Update the recorded count/grid above after packing the final asset.

ART-REVIEW: composition continuity between the supplied clips, phase lighting,
sun/shadows, landmarks, magenta surround, square presentation and portrait bounds.
