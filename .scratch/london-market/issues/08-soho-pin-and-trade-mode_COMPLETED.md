# 08 — Soho pin and Trade mode

**What to build:** Once unlocked, a Soho pin appears on the map and opens the existing Trade view in a new Soho mode. The player can buy and sell ore and items, see stock and price for each good and tier, and choose a tier. Empty goods show as empty. The current fee and net result show on the order. The screen only reads Soho rows and calls Soho functions.

Spec: `.scratch/london-market/spec.md`, "Soho Marketplace", "Trading screen", delivery step 7. Stories 19-20, 48-49, 51-54, 58, 63.

**Blocked by:** 07

**Relevant files:** `systems/map_pins.gd`, `scenes/components/map_canvas.gd`, `scenes/modals/sell_menu_view.gd`, `scenes/modals/sell_menu_modal.gd`, `systems/soho.gd`, `tests/test_map_pins.gd`, `docs/ui-vision.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] No pin before unlock; pin present after unlock and on a backfilled save
- [ ] Tapping the pin opens Trade in Soho mode
- [ ] Buy and sell work for ore and for items by tier
- [ ] Stock and price show per good and tier
- [ ] Empty goods show as empty and cannot be bought
- [ ] The screen holds no game logic and mutates no state
- [ ] The other Trade modes behave as before
- [ ] Pin logic is tested through `MapPins`; layout goes to human on-device QA
- [ ] `CODEMAP.md` is updated
