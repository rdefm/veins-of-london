# PRD — Map Filters & Visuals

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

Chunk 2 (district shapes) locks in dropping the aged-paper texture for a flat, clean background — this PRD designs what replaces it, and extends the filter row (N4) to work with real multi-faction lines now that Chunk 1 exists.

## Depends on

- **Chunk 1 (Faction Vein Ownership)**: faction identity/colour needed for the new filter mode.
- **Chunk 2 (Map rendering)**: the background pivot this PRD details.

## Rules

### Background & theme

- No app-wide light/dark theme system exists today (confirmed — no theme-mode code anywhere in the project). The Network map gets a **single fixed look**, not theme-aware: a light/off-white flat background (classic tube-map look), not dark mode.
- Existing glyph grammar (N2: circle r7 + ore symbol for veins, tick marks for unclaimed sites, level/security badges, padlocks, line width/caps) is **kept as-is** — only recoloured/repositioned to sit on the new flat background. The paper texture was what read as dated, not the glyph grammar itself; no redesign of stop/line visual weight in this pass.

### New filter mode: faction isolate

- Filter row (N4) gains a 6th chip: **Faction**. Tapping it reveals a small secondary picker (sub-row/menu) listing the 5 canonical factions, plus a way to clear back to "all."
- Picking a faction dims everything else and highlights just that faction's line + owned stops — same alpha-fade pattern the existing filter modes already use (e.g. Charge mode dims uncharged stops to 35%).
- This keeps the primary filter row uncluttered (no need for 5 more top-level chips, one per faction).
- The existing 5 filter modes (Ownership/Type/Strength/Charge/Security) are unchanged in behaviour — this is additive.

## Explicitly out of scope for this pass

- No changes to the existing 5 filter modes' own logic.
- No legend modal or district-label/typography changes.
- No app-wide theme system (light/dark) — the map's background is a one-off fixed choice, not tied to a broader theme feature.

## Open questions for the later ticket-level spec

- Exact background colour value (which off-white/light tone) and how faction/player line colours (already fixed in `factions.json`/`PLAYER_COLOUR`) read for contrast against it — may need contrast tuning, not a new palette.
- Exact sub-picker UI shape (dropdown vs. inline secondary chip row vs. modal) for the Faction filter's 5-faction picker.
