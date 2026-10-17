# 01 — Add districts in the west and southwest

**What to build:** Five new London districts on the west/southwest side of the current map — Notting Hill, Kensington, Chelsea, Hammersmith, Clapham — fully playable: they appear on the Network Map in sensible geographic positions, can be prospected, roll sites with their own ore weights/terroir, have a siteCap, and draw from the district event deck (new events or generic deck entries as M1-LONDON's framework allows). Each district gets short flavour copy drafted against CONTENT-GUIDE.md.

**Blocked by:** None — can start immediately

**Relevant files:** `data/districts.json`, `data/map_layout.json`, `systems/districts.gd`, `systems/district_deck.gd`, `systems/sites.gd`, `scenes/components/map_canvas.gd`, `systems/map_view.gd`, `docs/M1-LONDON.md` (districts, prospecting, event framework), `docs/M1.5-NETWORK-MAP.md` (layout/glyph grammar), `docs/CONTENT-GUIDE.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Five new districts exist in data with all fields existing districts have (ore weights, siteCap, name, flavour)
- [ ] Network Map places them west/southwest of current districts without overlapping lines/stops; existing layout still readable
- [ ] Prospecting works in each new district (headless test: prospect yields a site with that district id)
- [ ] District event deck can fire in new districts without errors
- [ ] District lists in docs/REFERENCE.md / M1-LONDON.md updated
- [ ] New prose flagged `PROSE-REVIEW:` in report
