# 74 — Map: faction line spacing and guaranteed no-overlap with other factions' veins

**What to build:** Faction connector lines on the network map should never visually touch a vein that isn't theirs, and when two different factions' lines run close together they need visible separation rather than nearly overlapping. A prior ticket already added best-effort avoidance of crossing another faction's vein icon, but it can still silently fail (when neither of its two routing options clears the obstacle, it falls back to one that crosses anyway) — that gap needs closing. Line-to-line spacing between different factions was never addressed at all.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Two different factions' lines running adjacent/parallel to each other maintain a visible minimum gap (**needs balance/visual sign-off** — propose a specific value, flagged for the human to eyeball and adjust).
- [ ] A faction's line reliably never visually crosses through a vein icon it doesn't own — including the case where the existing two routing options both fail to clear it (add a further fallback rather than defaulting to a crossing path).
- [ ] Existing river-avoidance and other-faction-avoidance behaviour is preserved.
- [ ] New test case: a layout where both existing routing options cross an obstacle, confirming the new fallback avoids it.
- [ ] Manual check noted for the human: play until several factions hold adjacent territory and visually confirm no line crosses a non-owned vein and adjacent lines stay visibly separated.
