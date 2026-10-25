# 03 — Event title wraps one character per line when there's no image

**What to build:** On an event card with no image, the event's name renders one character per line, which suggests its label has collapsed to near-zero width. The title should lay out normally across the card's width, the same as on cards that have an image.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/event.gd` (card header/title layout, image-less path), `docs/ui-vision.md` (typography).

**Status:** ready-for-agent

- [ ] An image-less event shows its title on one line (or wrapped by word at full width)
- [ ] Events with images are unchanged
- [ ] Headless check: on an image-less event, the title label's width matches the card's content width (not ~1 char)

On-device check: open an event with no image and confirm the title reads normally.
