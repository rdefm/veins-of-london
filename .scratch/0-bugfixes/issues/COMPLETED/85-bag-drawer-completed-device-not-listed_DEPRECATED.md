# 85 — Bag drawer: completed device doesn't appear to equip

**What to build:** Fix the bug where a device built to completion at HQ never appears in the Bag drawer to equip. Equip stays Bag-only (rejected: adding a second equip surface, e.g. at HQ) — this is purely about making the completed-but-unequipped device actually show up where it already should. Reproduce the real end-to-end path (build a device to completion, then check both the player's completed-devices state and the Bag drawer's rendered output) rather than only testing the drawer's render logic against hand-built state, since that's already covered and passing. Leading hypothesis: the Bag's read-only fallback view is gated on whether combat is active, and that flag may be able to get stuck true outside of an actual fight the same way the map's animation-queue flag was found to leak (ticket 81) — if so, find and close the actual interruption path rather than patching the symptom with a safety reset.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A device built to completion at HQ appears in the Bag drawer's equip view without requiring any workaround.
- [ ] Root cause confirmed end-to-end (not assumed) — including verifying the completed device actually lands in the player's completed-devices state after the build finishes.
- [ ] If the combat-active-stuck-true theory is confirmed, the actual interruption path that leaves it stuck is found and closed, not just papered over with an unconditional reset.
- [ ] Regression test covering the real completion-to-equip path (not just the drawer's render function against hand-built state).
