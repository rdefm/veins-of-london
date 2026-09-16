# PRD — Map Animations

**Status:** Draft, from a `/grill-me` session (2026-08-07).

## Why

The Network map currently only animates one thing: the continuous idle "charged" halo pulse (`ChargeHalo`, loops while `vein.charged == true`). Every other state change (a site being discovered, a vein being seeded/claimed, a vein joining an owner's line, a vein finishing charging, a vein draining) just appears instantly on the next `state_changed` redraw. This PRD adds one-shot transition animations for those moments, on top of the existing idle loop.

## Depends on

- **Chunk 1 (Faction Vein Ownership)**: "vein joins a faction's line" only exists once faction claiming is real.
- **Chunk 2 (Map rendering)**: multi-faction line routing this animates.

## Rules

### Trigger & queueing

- Map-worthy events (discover, seed/claim, join-line, charge, drain) are collected per daily tick into a queue, not played immediately as they occur in game logic.
- The queue **does not force-switch the player to the Map tab**. It waits silently and plays automatically the next time the player navigates to the Map tab themselves — consistent with the rest of the app's reactive (state-driven, not navigation-driven) redraw model.
- When the queue plays, events run **sequentially**, one at a time — not simultaneously — and before each event's animation plays, the camera pans/zooms to that event's map location. This makes the replay read as a guided tour of "what changed today," not a burst of simultaneous effects the player has to visually hunt for.
- The player can **tap to skip the currently-playing event** — this snaps it straight to its end state and immediately advances to the next queued event (which still plays at normal pace unless also tapped). Per-tap, not a persistent speed ramp.

### Pacing

- Default pacing is **deliberate** (roughly 1-2s per event) — these are meant to feel like real moments, not micro-interaction chrome.
- A settings toggle lets the player switch to a **quick/snappy** pacing (roughly 200-500ms) for repeat playthroughs where the novelty has worn off. Exact setting location TBD at implementation (likely alongside other player-facing toggles, not in `GameState` — this is UI-local preference, same category as filter_mode's "not saved, not in GameState" treatment in N4).

### Per-event visual treatment

- **Site discovered**: a soft ring pulses outward once from the location (ripple), then the unclaimed tick-mark glyph pops in at its centre.
- **Vein seeded/claimed** (player seeding, or a faction's claim-tick creating one): the vein stop's coloured ring **draws itself in progressively** around the stop, like a circular loading-spinner filling from 0 to 360° (reuses the existing `draw_arc` primitive already used for vein rings, animated over the arc's `0 -> TAU` sweep instead of drawn instantly at full circumference).
- **Vein joins a faction's/the player's line**: the connecting line segment **visibly grows** from the nearest existing point on that owner's line to the new stop, over the animation's duration — not a snap to the final routed shape. This is the direct answer to the original ask ("test the vein connection/generation") — the connection process itself is what's shown, not just the end state.
- **Vein finishes charging**: a brighter one-shot burst/flash at the stop, then settles into the existing continuous idle pulse loop (`ChargeHalo`) — unchanged.
- **Vein drains**: the halo visibly **collapses/shrinks inward and fades out**, marking the moment it stops (the reverse shape of the charge burst), rather than the halo just disappearing.

## Explicitly out of scope for this pass

- No changes to the existing continuous idle "charged" pulse loop itself (`ChargeHalo`) — only the one-shot transition moments around it.
- No changes to what triggers charge/drain/claim/discover in game logic — this PRD is purely about how already-happening state changes get shown.

## Open questions for the later ticket-level spec

- Exact queue data shape (what a "map event" record needs — type, location, owner/faction, before/after state) and where it's populated (daily tick step) vs. drained (Map tab `_ready`/`state_changed`).
- Exact camera pan/zoom implementation on top of `MapZoom`'s existing manual pinch-zoom (`_apply_zoom`, `zoom_level`) — needs a programmatic "pan+zoom to point" path that didn't exist before (today zoom is only ever pinch-driven).
- Exact settings-toggle UI/location for the pacing preference.
