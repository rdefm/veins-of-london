# 02 — Framed card, fixed text box

**What to build:** The event card matches `.scratch/event-card-restructure/Example format.PNG`. One dark rounded outer frame holds both the image and the cream text panel beneath it, so the image and the text box share a consistent border. The text box is always the same fixed pixel height and never grows or shrinks (today it grows upward when choices stack); the image takes whatever height remains. Prose that overflows scrolls inside the box. Cream becomes the standard event text panel, and ui-vision is updated to say so.

**Blocked by:** 01 — One layout for every event.

**Relevant files:** `scenes/screens/event.gd` (`_build_vn_frame`, `_refresh_vn_frame`, `_refresh_vn_card`, `_style_card`, `VN_TEXT_FRAME_HEIGHT`, `VN_BOTTOM_MARGIN`, `VN_CARD_PADDING_H`), `scripts/ui.gd` or wherever `UI.card()` lives, `docs/ui-vision.md` §6 "Colour rules across all four families" and §11 "Event/dialogue cards", `tests/test_event_screen.gd`, `.scratch/event-card-restructure/Example format.PNG`.

**Status:** ready-for-agent

- [ ] Image and text panel sit inside one dark rounded frame with matching borders, as in the example screenshot
- [ ] Text panel is cream, with dark body text and the muted label style from the screenshot
- [ ] Text box height is identical across prose cards, choice cards and stacked choices (test asserts the height doesn't change)
- [ ] Long prose scrolls inside the box; the image never shrinks to make room
- [ ] ui-vision §6/§11 records cream as the event-panel standard
- [ ] Human on-device check listed in the report: frame, cream panel, fixed height on a phone-width screen
