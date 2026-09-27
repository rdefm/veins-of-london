# 05 — Owned-vein action buttons run off the right edge of the screen

**What to build:** On the site/vein sheet for a vein the player owns, the action buttons (Cultivate, Harvest cautious, Harvest full) currently sit in a single row that overflows past the right edge of the screen once the vein is charged (all three buttons showing at once). All actions must fit fully on-screen and stay tappable, at any vein state.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] With a charged, owned vein (all three action buttons present), every button is fully visible and tappable within the screen width — none clipped or pushed off-edge.
- [ ] With an uncharged vein (Cultivate only), layout still looks correct.
- [ ] Behaviour on narrow (small phone) widths specifically checked, since that's where the overflow was reported.
