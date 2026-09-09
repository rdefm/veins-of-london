# 19 — Umbrella art: reposition grey screw circles to 2/4/8/10 o'clock

**What to build:** A new `dial_device_base.png` with the four grey screw
circles ringing the clock face repositioned to sit roughly at the 2, 4, 8,
and 10 o'clock positions, so they visually align with where the
complication slot boxes sit (ticket 17). This is a human task, not an
AI-pixel-art-pipeline one: `dial_device_base.png`/`dial-needle.png` are a
human-supplied photographic-style asset (measured by pixel inspection in
existing code comments, not generated via `docs/ART-BIBLE.md`'s
combat-pixel-art prompt/`tools/pixelize.py` pipeline), so this needs the
original source edited and re-exported at the same 500×500 native canvas,
not a fresh AI generation.

Once new art lands, ticket 17's slot-box positions (`SOCKET_ROW1_Y`/
`SOCKET_ROW2_Y`/flanking x-offsets in `hq_dial.gd`) may need a follow-up
tweak to land exactly on the new screw positions — not included here.

**Blocked by:** None — can start immediately

**Status:** ready-for-human

- [ ] New `dial_device_base.png` with screws at ~2/4/8/10 o'clock, same 500×500 native canvas and cream dial-face bbox position (or `FACE_CENTER_NATIVE` updated to match if it moves)
- [ ] Asset dropped in at the existing path, no code changes required to land it
- [ ] Human confirms on-device that the slot boxes (ticket 17) read as aligned against the new art; follow-up positioning ticket filed if not
