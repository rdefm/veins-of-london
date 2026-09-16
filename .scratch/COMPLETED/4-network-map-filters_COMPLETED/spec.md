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

- The 6 filter modes (existing 5 + new **Faction**) live as list items in the hamburger drawer (see "Entry chrome" below) — not a 6th top-level chip, superseding this PRD's original chip-row framing.
- Faction is a two-step pick: tapping "Faction" in the drawer reveals the 5 canonical factions plus a way to clear back to "all."
- Picking a faction dims everything else and highlights just that faction's line + owned stops — same alpha-fade pattern the existing filter modes already use (e.g. Charge mode dims uncharged stops to 35%).
- The existing 5 filter modes (Ownership/Type/Strength/Charge/Security) are unchanged in behaviour — this is additive.

### Entry chrome (resolved 2026-08-09, reference: tube-map app screenshots; amended 2026-08-09 after on-device testing)

- The Map tab's in-page header (today: back button, "The Network" heading, muted hint) is replaced by a local top bar: **hamburger (left) / "The Network" title (centre) / bag icon (right)**. This is Map-screen-local chrome, distinct from the app-wide `TopBar` (cash/day/bag) that persists on every other screen.
- Tapping the hamburger opens a drawer that replaces the filter chip row entirely: all 6 filter modes as a list (radio-style, one active), plus the pacing toggle (deliberate/quick) and the legend ("?" → Network Reference modal) grouped below, matching the reference screenshot's sectioned list (Map modes, then other actions).
- The map now opens at a moderate zoomed-in default (`MapZoom.DEFAULT`, currently `0.5`) rather than the zoomed-to-fit-everything view — exact value picked during implementation, between today's `0.5` and the existing `MapZoom.EVENT_ZOOM` (`0.8`).
- **Amendment (on-device feedback, 2026-08-09):** the Map tab is now full-screen chrome — the app-wide `TopBar` is hidden on this screen (its bag button's job is covered by the local top bar's own bag icon), and the old header's back button is dropped entirely rather than relocated (Home is still reachable via every other tab's own back button). Only the local hamburger/title/bag bar and the 5-tab `NavBar` remain visible on Map. This supersedes the "no changes to the app-wide TopBar" line under "Explicitly out of scope" below.

## Explicitly out of scope for this pass

- No changes to the existing 5 filter modes' own logic.
- No legend modal *content* changes (it still opens from the drawer now, not the old "?" chip, but its rows are unchanged) or district-label/typography changes.
- No app-wide theme system (light/dark) — the map's background is a one-off fixed choice, not tied to a broader theme feature.
- `NavBar` (5 bottom tabs) stays exactly as it is on every screen including Map. The app-wide `TopBar` no longer applies to Map specifically — see the Entry chrome amendment above.

## Resolved (was open questions)

- Background colour: keep tuning against the flat fill already shipped (Chunk 3) — see ticket 01.
- Sub-picker/filter-UI shape: hamburger drawer (see "Entry chrome" above), not a dropdown/inline chip row/modal.
