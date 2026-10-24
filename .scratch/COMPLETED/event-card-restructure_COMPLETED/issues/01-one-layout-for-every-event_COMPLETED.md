# 01 — One layout for every event (blank card + id tag)

**What to build:** Every event plays in the image + text-box layout, including the events that have no art yet. A card with no image shows a blank image panel tagged `<eventId> · card N`, so writing and formatting can be playtested in the final format before assets exist. The old no-art layout (a scrolling stack of text cards with a full-width Continue bar) is removed, so there is only one event layout.

**Blocked by:** None — can start immediately (prefactor for the rest of the set).

**Relevant files:** `scenes/screens/event.gd` (the VN/non-VN split, `_build_vn_frame`, `_refresh_vn_card`, `_refresh_image_slot`, `_build_image_frame`), `systems/events.gd` (`is_vn_mode`, `current_image_path`, `_convention_image_path`), `tests/test_event_screen.gd`, `docs/ui-vision.md` §11 "Event/dialogue cards", `CODEMAP.md` (`event.gd`, `events.gd` rows).

**Status:** ready-for-agent

- [ ] An event with no art at all plays in the image + text-box layout
- [ ] An imageless card shows a blank image panel with the `<eventId> · card N` tag
- [ ] A card with art shows the art and no tag
- [ ] The old stacked-card layout code path is gone; nothing still branches on "VN mode"
- [ ] Rewind, Item button, choices, checks and gated options still work in the single layout (existing tests pass, adapted where they asserted the old layout)
- [ ] ui-vision §11 and CODEMAP describe the single layout
