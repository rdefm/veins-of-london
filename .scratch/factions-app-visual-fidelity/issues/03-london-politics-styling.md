# 03 — London politics styling

**What to build:** The existing tappable relationship matrix reads like the mockup's compact politics page, with faction identity, stance colours and a clear selected pair.

**Blocked by:** 01 — Register shell and home.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/components/contact_cards.gd`, `scenes/components/ui.gd`, `tests/test_phone_apps.gd`, `tests/test_phone_nav.gd`, `CODEMAP.md`; visual reference: `.scratch/factions-app-redesign/mockup.html`.

- [ ] Page uses the Register masthead and mockup's orange back link, **LONDON / Politics** heading and short instruction on the dark canvas, without a generic cream card.
- [ ] Compact upper-triangle matrix fits phone width. Row labels show faction-colour dots and legible short names; column abbreviations are distinct. The ten tappable cells have restrained stance fills for Partner, Business rival, Hostile and Neutral, retain their P/R/H/· symbols, and show the selected cell with an oxide outline rather than the generic disabled appearance.
- [ ] A compact, wrapping legend and a bordered pair-detail strip show both selected factions, stored stance, signed raw relation and any war/truce. Selection remains visible after refresh and does not change gameplay state.
- [ ] Automated checks retain all ten pair and selection coverage; on-device comparison includes a selected hostile/war pair and narrow-width legibility/tap targets. Godot 4.7 syntax and full tests pass. Flag any new prose with `PROSE-REVIEW:`.
