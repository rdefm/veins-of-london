# 77 — Vein growth indicator: radial fill redesign

**What to build:** The map's growth indicator (an arc gauge plus a per-band edge texture plus a numeral+arrow "days to wall" badge) is unclear — players can't tell a vein's growth state at a glance. Replace all three parts with a single radial fill meter behind the vein's ore-type icon: the fill level directly represents how full the vein is (empty at zero growth, full at the growth ceiling), colored with the vein's existing owner color (the player's map color, or the owning faction's color) rather than a separate meaning-coded gradient — keeping it consistent with how ownership is already color-coded elsewhere on the map.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Every vein icon on the map shows a radial fill behind its ore-type icon, filled proportionally to growth/ceiling.
- [ ] Fill color is the vein's owner color (player amber, or the owning faction's color) — flat, not gradiented by growth level.
- [ ] The old arc gauge, per-band edge texture (serrated/gapped/plain), and the numeral+arrow days-to-wall badge are all removed from the map icon.
- [ ] The days-to-wall information is dropped entirely — not relocated elsewhere (confirmed with the human; the site sheet's raw "Growth: X/Y" text and bar are unaffected and stay as the detailed view).
- [ ] Fill renders correctly at growth 0 (empty) and at/above ceiling (full) without visual glitches.
- [ ] Manual check noted for the human: view veins across the full growth range (freshly collapsed, dormant, rampant) and confirm the fill level reads clearly at a glance, and that faction veins show their faction's color correctly.
