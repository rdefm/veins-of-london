# 15 — Swap placeholder list for the real diagram

**What to build:** replace M1's plain district-list Map tab with the real `MapCanvas` diagram as the Map tab's top-level view. District panel and site/vein sheet are unchanged from M1 (ticket 04) — only the top-level presentation swaps from list to diagram.

**Blocked by:** 13, 14.

**Status:** ready-for-agent

- [ ] Map tab's top-level view is the real diagram; the plain list from ticket 04 is fully retired
- [ ] Tapping a stop/tick opens the same site/vein sheet as before (no behavioural regression)
- [ ] Tapping a district zone/label opens the same district panel as before (no behavioural regression)
- [ ] Human visual QA: from any save state (including debug start), confirm every ownership change, discovery, seed, charge, and security change appears on the diagram without restart, and a newly seeded vein visibly joins the player's line
- [ ] Confirms M1.5 exit criteria 1–3 from `docs/M1.5-NETWORK-MAP.md`
- [ ] `godot --headless --check-only --script` clean on all touched files
