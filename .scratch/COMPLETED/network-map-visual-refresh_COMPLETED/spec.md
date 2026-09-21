# Network map visual refresh

## Goal

Refresh the Network map's site glyphs, stop markers, zoom control, and faction key to the cream/charcoal/gold visual language shown in the supplied mockups. Preserve map mechanics, navigation, filtering, and touch behaviour.

## Mockup index and authority

The source images are stored with this feature:

| Reference | Path | Use |
|---|---|---|
| Photo 1 — Site Type Glyphs | [`mockups/01-site-type-glyphs.jpg`](mockups/01-site-type-glyphs.jpg) | Canonical glyph silhouettes, white marker centres, charcoal glyphs, neutral ring track, gold radial fullness arc. The mockup's “Chance” label is not authoritative: the canonical type remains **Fate**. |
| Photo 2 — Expanded key/map | [`mockups/02-expanded-faction-key-map.jpg`](mockups/02-expanded-faction-key-map.jpg) | Expanded faction-key composition, cream card, swatches, border/shadow, and marker legibility on the map. |
| Photo 3 — Site card/map | [`mockups/03-site-card-map.jpg`](mockups/03-site-card-map.jpg) | Site-detail card is the material/style reference: cream surface, charcoal text/icons, rounded corners, subtle border/shadow, restrained gold. Also shows the faction key's compact form. Its vertical zoom layout is not authoritative. |
| Photo 4 — Key states | [`mockups/04-faction-key-states.jpg`](mockups/04-faction-key-states.jpg) | Expanded/collapsed faction-key states. Orange separate zoom buttons are an old treatment and must not be copied. |

Written decisions override images where they disagree.

## Locked decisions

- Canonical ore IDs and names stay `time`, `physics`, `life`, `fate`, `emotion`. Player-facing **Fate** remains Fate; dice is its glyph.
- Glyphs: Time = hourglass, Fate = dice, Life = sprout, Physics = lightning bolt, Emotion = heart.
- Every stop uses a white-filled circular centre with a charcoal glyph. Glyph shape communicates type; fullness/status never changes the glyph itself.
- A claimed site's vein fullness is `growth / Cultivating.ceiling(vein)`, clamped 0–1, rendered as an external radial progress ring. Player and faction-owned veins follow the same grammar.
- Unclaimed sites render the same centre and glyph with an empty ring: visible neutral track, zero progress.
- Existing rich/saturated concentric interchange/terroir ring remains. It must remain distinguishable from the fullness ring.
- Default fullness styling follows Photo 1: muted neutral remainder plus restrained gold progress. Existing filter modes remain functional; where a mode currently recolours the growth treatment, it may recolour the progress arc, but not the white centre or charcoal glyph.
- Zoom control is one horizontal pill ordered `−  +`. This overrides every mockup's vertical/separate-button geometry.
- Faction key starts collapsed whenever the Map screen/component is constructed. State is UI-local and not persisted. Whole header toggles it; collapsed content is only `Factions` plus chevron.
- Cream surfaces, charcoal text/icons, subtle low-contrast borders/shadows, rounded corners, and restrained gold accents must visually match the site-detail card aesthetic in Photo 3.

## Non-goals

- No mechanics, data schema, state tree, save format, map routing, zoom range/step, map navigation, or site-detail content changes.
- No ore renames or data migrations.
- No replacement of ownership lines, security badges, terroir semantics, filters, event animation, or stop tap behaviour.
- No redesign of the site-detail card; it is a style reference only.

## Implementation order

1. Site glyph set.
2. Standard stop marker and fullness-ring grammar (depends on glyph set).
3. Horizontal zoom pill (independent).
4. Collapsible faction key and shared surface styling (independent).

## Completion contract

- Update `docs/M1.5-NETWORK-MAP.md` where its glyph/growth-fill contract conflicts with these approved decisions.
- Syntax-check every touched `.gd` immediately with the configured Godot 4.7 console binary and `scripts/check_runner.gd`.
- Run `scripts/run_tests.sh`.
- Human visual QA on a phone is required for sizing, contrast, shadows, progress-ring legibility, and touch targets.
