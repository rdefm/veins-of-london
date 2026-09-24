# Daily animation revamp

Replace the current tiny, full-screen time-block interstitial with a compact, circular pixel-art animation over the screen the player was using. This is presentation only: time advancement, daily effects, queueing, save/load, and Rewind behaviour stay as specified in `docs/REFERENCE.md` §3.1.

## Agreed presentation

- On a 390 px-wide phone, the artwork sits inside a **220 px-diameter circle**. Keep the park bench, tree, and **recognisable London buildings** readable at that displayed size. The landmark buildings must be coloured, shaded pixel art in the same visual style as the tree and bench, with broad pixel clusters rather than miniature architectural detail. St Paul's, Parliament / Elizabeth Tower, and the Shard are the reference landmarks.
- The circle rises into view over the current screen, plays the sky change, then drops below the bottom edge. The screen remains visible behind a dim layer throughout. The transition must not jump to a blank dark screen.
- The circle contains a pixel-art sky with visibly **round** sun and moon forms; neither may render as a square. Evening → Morning: moon sets, sun rises. Morning → Afternoon: sun starts to set. Afternoon → Evening: sun sets, moon rises. Rest traverses any remaining phases in order, as the current presentation does.
- Block all taps, clicks, keyboard/gamepad input and held releases while visible. Keep the existing outcome hold, 1.75-second presentation duration, reduced-motion static destination, and transient queue semantics unless the canonical spec is explicitly changed.
- Preserve the destination day/phase label. Position it with the circle so both enter and exit together.

## Art status

`references/park-foreground-v3.png` is the current **candidate**, not final approved in-game art. It has transparent sky for a separately animated sun, moon, and sky; confirm its legibility and pixel style at the actual 220 px circle size on a device. `references/park-foreground-v2.png` is the preceding, more detailed candidate. `references/current-cycle-atlas.png` is the existing 73 px atlas for comparison.

The previous HTML mockup failed to show the foreground image and depicted the sun as a square. It is not an implementation reference. The implementation must be verified in Godot on a phone-sized viewport, then visually checked on-device.
