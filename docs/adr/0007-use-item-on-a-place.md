# Using items on a place (Root Feed, Good Year, Deadweight)

Decision record for `item-event-effects` ticket 12. **Partly approved
2026-11-02**; the HQ entry point is proposed, not yet signed off.

## Decision

- **Place-side action, not a Bag picker.** Items that target a vein get an
  "Apply item…" action on the place itself, listing eligible Bag items.
  Entry points: the Vein list row, and the mini vein card shown when a vein
  is tapped on the Network Map. Both call one shared system function; the
  screens never mutate state.
- **Stacking.** One active effect per item id per place. Reusing the same
  item on the same place refreshes its duration; it does not stack. Different
  items coexist (Root Feed + Good Year is the intended cultivation pair).
- **Storage.** Active effects are pure data on the place (`vein.boosts`,
  entries with an expiry day number); expiry is checked in the daily tick.
- **Deadweight on HQ (PROPOSED).** The HQ screen (`systems/home.gd`) gets the
  same "Apply item…" action, storing the boost on the HQ/stockpile. Needs
  human confirmation.

## Consequences

- Ticket 13 (Root Feed, Good Year) builds the shared apply function and the
  Vein list / mini card entry points.
- Ticket 14 (Deadweight) reuses it and adds the HQ entry point.
- Bag drawer stays a viewer; it gains no targeting flow.
