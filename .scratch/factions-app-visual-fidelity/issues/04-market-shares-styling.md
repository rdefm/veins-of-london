# 04 — Market shares styling

**What to build:** The existing market share view matches the mockup's readable oxide-orange brand treatment: selected tally, glyph tabs, and labeled percentage bars.

**Blocked by:** 01 — Register shell and home.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/components/contact_cards.gd`, `scenes/components/ui.gd`, `data/ore_types.json`, `tests/test_phone_apps.gd`, `tests/test_shares.gd`, `CODEMAP.md`; visual reference: `.scratch/factions-app-redesign/mockup.html`.

- [ ] Page uses the Register masthead and mockup's orange back link, **LONDON / Market shares** heading and live share-window caption on the dark canvas, without a generic cream card.
- [ ] Ore/Crafting is a two-part control with the selected tally filled oxide orange and readable dark text. The five canonical ore glyph/name choices read as compact tabs with an orange selected underline; selection remains clear without relying only on colour.
- [ ] The selected ore/tally heading has a glyph. Each producer is a flat divided row with its name and exact percentage on one line, then a dark track and strong solid oxide-orange fill proportional to that share. Keep You and Independents where returned by the existing overview. Avoid the current generic button styling and pale/translucent share fills.
- [ ] Switching tally or ore preserves the existing calculations and view state. Automated checks retain selection and producer coverage; on-device comparison includes Ore and Crafting states and all producers at narrow width. Godot 4.7 syntax and full tests pass. Flag any new prose with `PROSE-REVIEW:`.
