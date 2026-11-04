# Using items on a place (Root Feed, Good Year, Deadweight)

Decision record for `item-event-effects` ticket 12. **Approved 2026-11-02.**

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
- **Deadweight on HQ.** HQ's only placeable item. It only reduces ore lost
  to raids. Entry point is an "Apply Deadweight" option in the HQ ore
  readout modal (`scenes/modals/hq_ore_readout_modal.gd`), not a general
  HQ "Apply item…" action.

## Consequences

- Ticket 13 (Root Feed, Good Year) builds the shared apply function and the
  Vein list / mini card entry points.
- Ticket 14 (Deadweight) reuses it and adds the HQ ore readout modal option.
- Superseded in part (authoring pass ticket 08): the Bag drawer also offers a
  target picker (veins; HQ for Deadweight; contacts for Smelling Salts;
  grudges for Clean Slate) calling the same apply functions. Place-side
  entry points remain.
