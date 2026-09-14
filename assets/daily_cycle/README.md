# London time cycle

Source: user-supplied `morning_to_afternoon.zip`, `afternoon_to_evening.zip`, and
`evening_to_morning.zip`.
Original pixels, colours and square composition preserved, including the supplied
magenta surround. No generated/repainted frames or runtime art layers.

- 42 frames, row-major 7 × 6 atlas, 73px cells, **511 × 438px** texture.
- Morning → Afternoon: frames 0–13, native **73 × 73px**.
- Afternoon → Evening: frames 14–27, native **72 × 72px**; cell padding excluded by region.
- At 390px portrait: centred **365 × 365px** and **360 × 360px** artwork respectively
  (5× integer scaling), fully visible, no crop. Destination label below the artwork;
  the artwork/label group is vertically centred. Width scales down in whole pixels
  on smaller viewports. Phone safe areas remain outside the central artwork.
- Lossless import, mipmaps disabled, explicit nearest filtering.
- Each interstitial lasts **1.75 seconds**, independent of frame count.
- Evening rollover plays Evening → Morning. Early Rest traverses every remaining
  phase clip, compressed into the same duration and labelled with the resulting
  day/Morning.
- Reduced motion holds the destination frame, with identical duration/input blocking.

ART-REVIEW: composition continuity between the supplied clips, phase lighting,
sun/shadows, landmarks, magenta surround, square presentation and portrait bounds.
