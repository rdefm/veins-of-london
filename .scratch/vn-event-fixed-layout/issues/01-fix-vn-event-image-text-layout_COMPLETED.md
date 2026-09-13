# 01 — Fix VN event image/text layout

**What to build:** Replace VN events' overlapping image and text presentation with one fixed, non-overlapping layout. The image occupies a fixed upper frame and the existing-size text box occupies a fixed lower frame. Art keeps its proportions and covers the image frame, so mismatched art may be centred and cropped/appear zoomed-in; it is never distorted or rejected. Text overflow scrolls inside the fixed box. Continue, Rewind, and choice controls remain inside that box and retain their current behaviour and styling.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] At the 390×844 baseline viewport, VN mode uses a documented fixed image/text split; the text box preserves the approved current footprint and no longer overlays the image.
- [ ] The fixed split is calculated within the usable area between top-bar and bottom safe-area clearances, remaining fully visible on supported viewport heights and safe-area configurations.
- [ ] The image frame uses aspect-cover behaviour: source proportions remain intact, the frame stays filled, mismatched aspect ratios are centred and cropped, and no dimension validation rejects an otherwise loadable image.
- [ ] The image never renders beneath the opaque text box.
- [ ] The text box keeps a fixed external height. Prose scrolls inside it when necessary; font size and box size do not shrink or grow to fit content.
- [ ] Continue, Rewind, and choice controls remain usable inside the fixed text box, including when prose overflows and on the tallest authored choice card.
- [ ] Current card-type treatments remain unchanged: tension danger border, craft calc colours, and neutral treatment elsewhere.
- [ ] Non-VN event layout remains unchanged.
- [ ] The event-image ADR and ART-BIBLE record the new fixed VN image canvas, fixed text-frame contract, non-overlap rule, aspect-cover cropping, and safe composition guidance. CODEMAP reflects the screen's revised responsibility.
- [ ] Automated coverage proves the fixed split, non-overlap, unchanged text-frame height across short/long cards, internal overflow scrolling, aspect-cover mode, safe-area handling, controls placement, and unchanged non-VN path.
- [ ] Syntax checks pass for every touched GDScript file and the full headless test suite passes.
- [ ] Human visual QA checks short prose, long prose, choices, Rewind, deliberately mismatched art, and a device with a bottom safe-area inset.
