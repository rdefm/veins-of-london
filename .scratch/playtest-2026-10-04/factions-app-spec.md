# The Register — Factions phone app layout

Approved in the 2026-10-12 design conversation. This replaces the long Factions phone-app page. The internal app id remains `factions`; gameplay systems and relationship formulas do not change. The interactive mockup's figures and scenario flags are illustrative; live game state supplies every value.

## Current content to retain

- London's ore/crafting share overview for You, factions and Independents, across five ore types.
- Player↔faction and faction↔faction stances, war and truce status.
- Per-faction name, tagline, description, archetype, primary/secondary ore, crafts, four relevant share values, player relation, join state, pressure, available actions, pending/owed favours, partner benefits/requests, intel-gated details, and full activity log.
- Existing Gift, Join, Guild Marketplace, partner price-favour, favour/trouble response and peace-talk flows, with their current gates, costs and effects.

## Brand

The launcher label and in-app wordmark become **The Register**. Use a five-node connected mark on its launcher icon and masthead, suggesting a directory of London's powers without implying ownership by any faction. Retain the shared phone frame/status bar and UI sans. Inside the app, warm graphite chrome and a strong oxide-orange brand colour (mockup `#e47a50`) distinguish it from the other phone apps. Use that brand colour for the masthead rule, selected controls, action buttons, and share fills. Use readable dark text on filled orange buttons. Faction colours identify factions only; the neutral relationship meter uses ink, not brand colour. Add the brand colour as a named palette value and document this app-specific exception in `docs/ui-vision.md`. The launcher icon keeps the existing 128×128 transparent PNG contract.

## Home: Your standing

Show exactly five compact rows in canonical faction order. Each entire row opens that faction's dossier. A row shows short name and faction-colour dot, stored player stance, signed raw relation value, a centred −100..100 meter with zero marker, and a concise live alert where relevant (war/truce or pending request). Stance and relation are separate reads: hysteresis or the Collective hold can make them temporarily differ. Do not infer stance from the displayed number. Below the rows, show two secondary routes: **London politics** and **Market shares**. The home page contains neither the pair matrix nor the share table.

## Faction dossier

Top: full faction name, tagline, signed relation and centred neutral meter, stored stance, current pressure and any war/truce. Then an **Available now** area for existing gated actions and current pending requests. Preserve all existing action routes and refusal reasons; do not add a new relation mechanic. Put pending/owed favour and partner-trouble information before archival detail.

Below: description, archetype, primary and secondary ore, crafts, Market footprint, Intel, Activity. Keep Market footprint visible; Intel and Activity may be collapsed initially but remain reachable in one tap and contain all previously visible, intel-gated information and the full newest-first log. Every structured ore-type label in the dossier has its canonical glyph from `data/ore_types.json` beside the name; use the existing glyph/fallback treatment where possible. Preserve authored request prose rather than parsing glyphs into free text; a structured request summary can show the relevant glyph when its ore type is available.

**Market footprint:** a compact grid with primary and secondary ore as columns, each headed by glyph and name; **Ore** and **Crafting** are the only rows. Each cell shows the exact percentage and fills horizontally by that percentage with the oxide-orange brand colour. The values are the existing per-faction `Shares` reads, with no changed denominator or rounding rule.

## London politics

A secondary page shows the ten unordered faction pairs in a tapable upper-triangular 5×5 matrix. Row labels use short faction names and identity dots; columns use legible abbreviations. Cells encode stored stance with **P** Partner, **R** Business rival, **H** Hostile, **·** Neutral; include a concise legend. Tap a cell to show both full names, stored stance, signed raw pair relation and any war/truce detail. The player's five relationships stay on the main page, not in this matrix. No politics action is added.

## Market shares

A secondary page retains the existing Ore/Crafting toggle. Pick one of the five ore types with its canonical glyph and name; show every producer returned by the existing `Shares` overview as a labeled horizontal percentage bar. The strong oxide-orange brand colour fills the bars; exact percentages remain visible. Changing tally or ore changes only view state. The existing share window and calculations stay unchanged.

## Navigation, acceptance and verification

- Home → any dossier / Politics / Market shares; each secondary page returns to Home; the app back route returns to the phone grid. A state refresh preserves the selected subview and does not duplicate controls.
- All values and enabled states come from the existing systems. No screen mutates game state directly. Preserve save/snapshot purity.
- Headless checks cover the five directory rows, relation/stance distinction, live navigation, conditional actions and intel gates, all ten pair cells with war/truce selection, and share/tally/ore selection. Run the full test suite with Godot 4.7.
- Human visual QA on a phone checks glyph rendering, readable orange button text, bar/cell fill clarity, matrix tap targets, and scrolling at narrow width.
- New UI prose receives `PROSE-REVIEW:` in the implementation report.
