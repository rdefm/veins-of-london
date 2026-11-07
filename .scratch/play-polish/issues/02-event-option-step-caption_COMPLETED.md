# 02 — Card text stays as a caption on the option step

**What to build:** On a choice card, options currently replace the card text in a fixed-height box, so with 3-4 options the player can lose sight of the challenge. After this ticket, when the options would hide the text, the card's own text stays visible as a caption over the lower part of the image, directly above the options. The player sees the challenge without tapping.

Long text clamps to about 3 lines, and tapping the caption shows the rest. No new prose is needed. It applies to any event, not just raids, and appears only when options would otherwise hide the text. Options and their order are unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/event.gd` (`_fill_options`, `_populate_card_text`, `_build_vn_frame`, `_refresh_vn_frame`, `_refresh_vn_card`, `VN_TEXT_FRAME_HEIGHT`), `docs/ui-vision.md`, `data/events/raid_shop.json` (cards `s_back`, `s_front`), `data/events/raid_arches.json`, `data/events/vein_raid.json`, `docs/adr/0005-event-image-asset-contract.md`

**Status:** ready-for-agent

- [ ] A choice card whose options would hide its text shows that text as a caption over the lower image
- [ ] A card with room to spare keeps its current layout
- [ ] Text over about 3 lines clamps with a visible cue, and tap reveals all of it, then closes back
- [ ] Caption stays readable over bright and dark art, in every event card style
- [ ] A choice card with no image still shows its text correctly
- [ ] Option tap targets, gating, the item menu and the context modal still work
- [ ] Tests cover when the caption applies, via a pure helper or the event screen; no state mutation in the screen
- [ ] Human on-device check lists `raid_shop` cards `s_front` and `s_back`, on a phone
