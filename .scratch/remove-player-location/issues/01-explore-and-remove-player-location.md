# 01 — Explore and remove the player's current location

**What to build:** The player can reach any point on the map within a turn, so the stored "where the player is standing" value (`world.currentDistrict`) has no gameplay purpose. Where it does do something, it creates arbitrary effects: prices that change with where the player last stood, events that act on "the current district", and a location reset every morning. Remove it as a gameplay input.

This is a two-phase ticket. **Phase 1 (explore and propose) must stop for human sign-off before Phase 2 (implement).**

### Phase 1 — explore and propose

Confirm and complete this inventory of every reader of `world.currentDistrict` (and of the district `priceMod` it feeds). Then propose a replacement for each, as a short table (reader → current effect → proposed replacement), and ask the human to choose. Don't invent a mechanic; offer 1–3 options per item with a recommendation.

Known readers as of 2026-09-25:

| Reader | Current effect | Decision needed |
|---|---|---|
| Archie's lane: offer pricing in `systems/archie_deals.gd` (two sites), Archie sell price in `systems/economy.gd` (~l.56), sell menu preview in `scenes/modals/sell_menu_view.gd` (~l.330) | Archie's prices move by the current district's `priceMod` (e.g. +15%) | Drop `priceMod` from pricing entirely? Or tie it to something non-location (e.g. the vein's or site's own district for vein sales)? |
| Faction lane price, `systems/economy.gd` `_faction_effective_price` | Adds a district modifier when `applyDistrictPriceMod` is true. **No lane sets it true today.** | Delete the flag and branch (likely) |
| Event effect `npc_claim_best_unclaimed_site`, `systems/events.gd` (~l.300) | A faction claims the best unclaimed site in the player's current district | Use the event's own district context (district-deck events know their district), or pick city-wide? |
| Combat location plate, `systems/combat.gd` `location_key_for` fallback | A fight with no vein uses the current district for its backdrop/location plate | Pass the district explicitly from the caller (e.g. a street mugging from a district event), or show no plate |
| Travel/map: `systems/travel.gd` (`ensure_district`, `travel_to`, `travel_via_wormhole` "Already there" guards), `scenes/components/map_canvas.gd` "you are here" marker, `scenes/screens/map.gd` (~l.299), the morning reset to Shoreditch in `systems/time_system.gd` | Bookkeeping, a no-op-trip guard, and the map marker | Remove the marker and guards? What does "travel" mean once location is gone (do the arrival rolls for district events and alarm-defend stay as "visit district X")? Wormhole's purpose if travel is free? |
| District list "Prices ±N%" indicator, `systems/districts.gd` `price_indicator` | Displays `priceMod` | Remove it if `priceMod` goes |
| `data/districts.json` `priceMod` field + its required-key check in `autoload/GameData.gd` | The data behind all of the above | Remove it, or keep it for a non-location use |

Also grep for anything this list missed. That includes REFERENCE.md/M1-LONDON.md/M1.5-NETWORK-MAP.md/VISION.md text that specifies location behaviour, plus the ~48 test references to `currentDistrict` under `tests/`.

### Phase 2 — implement the signed-off choices

- Remove `world.currentDistrict` from the state schema (`autoload/GameState.gd` default, REFERENCE.md §2) unless the sign-off keeps a presentational use.
- Loading an older save that still has `currentDistrict` must not fail. The key is simply ignored or dropped (no save-version bump unless the human says otherwise; §6 fills missing keys but check extra-key handling).
- Update the docs that specify location behaviour (REFERENCE.md, M1-LONDON.md, M1.5-NETWORK-MAP.md, VISION.md as found) and CODEMAP.md where a file's responsibility changes.
- Business Act 1 (`.scratch/biz-act1/spec.md`) already rules that business calc purchases never read location. This ticket must keep that true.

**Blocked by:** None — can start immediately. Phase 2 is blocked by the human's Phase 1 sign-off.

**Status:** ready-for-agent

**Relevant files:** `systems/archie_deals.gd`, `systems/economy.gd`, `systems/events.gd`, `systems/combat.gd`, `systems/travel.gd`, `systems/time_system.gd`, `systems/districts.gd`, `scenes/modals/sell_menu_view.gd`, `scenes/components/map_canvas.gd`, `scenes/screens/map.gd`, `autoload/GameState.gd`, `autoload/GameData.gd`, `data/districts.json`, `data/faction_trade.json`; REFERENCE.md §2 (world schema), §3.6 Selling (Archie lane), §6 Save format; M1-LONDON.md travel/district sections.

- [ ] Phase 1: complete inventory of location readers with options and recommendations, presented to the human; work stops until the human signs off.
- [ ] Phase 2: no gameplay outcome (price, claim, combat, event roll) depends on where the player last travelled.
- [ ] Map no longer shows a player position unless sign-off keeps one.
- [ ] Old saves containing `currentDistrict` load cleanly.
- [ ] Tests updated/added: prices identical across districts; `npc_claim_best_unclaimed_site` uses the signed-off district source; save-load with a legacy `currentDistrict` key.
- [ ] Docs and CODEMAP updated in the same commit.
