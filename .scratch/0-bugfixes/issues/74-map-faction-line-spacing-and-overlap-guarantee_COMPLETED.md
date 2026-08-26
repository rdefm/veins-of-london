# 74 — Map: faction line spacing and guaranteed no-overlap with other factions' veins

**What to build:** Faction connector lines on the network map should never visually touch a vein that isn't theirs, and when two different factions' lines run close together they need visible separation rather than nearly overlapping. A prior ticket already added best-effort avoidance of crossing another faction's vein icon, but it can still silently fail (when neither of its two routing options clears the obstacle, it falls back to one that crosses anyway) — that gap needs closing. Line-to-line spacing between different factions was never addressed at all.

**Amendment (2026-08-26 grill-me session):** The no-crossing guarantee needs to be hard — zero visible gaps/breaks in a line as a routing workaround. To achieve that, this ticket's scope now includes small position nudges: a vein's map position may shift slightly from its originally-assigned slot when needed to let a line avoid crossing it, not just further path-routing fallbacks. This is a bounded, explicit exception to `assign_positions()`/`next_slot_index()`'s existing "a stop's position is stable for its entire life" guarantee — a stop may move, but only by a small, capped distance, never a full relayout. This mechanism overlaps with ticket 87 (slot-index recycling), which also changes when/how a stop's position can move — coordinate if worked close together.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Two different factions' lines running adjacent/parallel to each other maintain a visible minimum gap (**needs balance/visual sign-off** — propose a specific value, flagged for the human to eyeball and adjust).
- [ ] A faction's line reliably never visually crosses through a vein icon it doesn't own — including the case where the existing two routing options both fail to clear it (add a further fallback rather than defaulting to a crossing path).
- [ ] When routing alone can't avoid a crossing, the blocking vein's position may shift by a small, capped distance from its originally-assigned slot (**needs visual sign-off** — propose a specific max-offset in map px).
- [ ] Decide and document whether a position shift animates (e.g. reusing the existing animation-safe "ends where the static draw already computes" growth pattern) or snaps, and implement accordingly.
- [ ] Existing river-avoidance and other-faction-avoidance behaviour is preserved.
- [ ] New test case: a layout where both existing routing options cross an obstacle, confirming the new fallback (routing and/or position nudge) avoids it.
- [ ] Manual check noted for the human: play until several factions hold adjacent territory and visually confirm no line crosses a non-owned vein, adjacent lines stay visibly separated, and any position nudges look natural rather than jarring.
