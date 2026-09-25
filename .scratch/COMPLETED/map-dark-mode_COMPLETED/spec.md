# Map dark mode — spec

Manual light/dark toggle for the Map tab only. Estimate and inventory: `.scratch/playtest-2026-09-24/issues/01-map-dark-mode-estimate_COMPLETED.md` (`## Answer` + `### Decisions`).

## Locked decisions (human, 2026-09-24)

1. Dark mode is an option on the Map tab only. The rest of the game is unchanged.
2. Stop centres and pin-head knockouts stay white, and ore glyphs stay charcoal, in dark mode. Paper, river, track, labels, halos, cards and chrome flip.
3. The Growth filter ramp runs `muted`→foreground (`ink` token), so it's light-on-dark in dark mode. Amend `docs/M1.5-NETWORK-MAP.md` §N4 to match.
4. Faction, ore, danger and action colours that fail 3:1 against the dark paper get lighter dark-only variants. Light mode keeps today's exact hexes.
5. The setting persists per save file as `meta.mapDarkMode`, set through `systems/preferences.gd` like `reducedMotion`. Default is `false`. Rewind/snapshots must never flip it.
6. The bottom nav dock also renders dark while the Map tab is showing.

## Shape

- `data/map_palette.json` has `light` and `dark` token sets, plus `dark`-only overrides for faction/ore colours. GameData loads and validates it.
- A presentation-side `MapPalette` accessor resolves a token against `meta.mapDarkMode`. `systems/map_style.gd` stays pure and gets colours passed in.
- The toggle lives in the Map controls drawer (`scenes/components/map_controls.gd`).

## Tickets

01 palette prefactor (no visual change) → 02 dark Network diagram (toggle + canvas) → 03 dark Map overlays ∥ 04 dark nav dock on Map (both blocked by 02).
