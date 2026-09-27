# 49 — Map: distinct pins for quests & Guild Marketplace

**What to build:** Two gaps: (1) quest-giver/contact pins currently use the generic event-pin mechanism (`Map_pins.active_contact_pins()`, `systems/map_pins.gd:14-26`, for `GameData.EVENTS` entries carrying a `pin` block) with no visual distinction from ordinary vein stops. (2) The Guild Marketplace (`scenes/screens/guild_marketplace.gd`) has zero map presence today — it's a standalone screen reached another way, with no representation in `map_pins.gd`, `map_layout.gd`, or `map_canvas.gd`. Per the human: give quest pins a glyph distinct from vein stops, and add a new Guild Marketplace pin at Guild's district — supplementing (not replacing) its existing access route.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Quest/event pins (`map_pins.gd`) render with a glyph/style visually distinct from vein-stop circles (e.g. a different shape, not just colour) in `map_canvas.gd`.
- [x] New Guild Marketplace pin added to the map at Guild's district, using its own distinct glyph (different from both vein stops and quest pins), tapping it opens the existing `guild_marketplace.gd` screen.
- [x] Marketplace remains reachable via its current existing route too — this is additive, not a replacement.
- [x] `docs/M1.5-NETWORK-MAP.md` glyph grammar section updated with the new pin types.
- [x] Manual check noted for the human: confirm quest pins and the marketplace pin are each visually distinguishable from vein stops and from each other, and that tapping the marketplace pin opens the marketplace screen. See report below.
