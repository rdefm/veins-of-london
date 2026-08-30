# 105 — Dial: HQ card Adjust Loadout / Craft Components nav

**What to build:** The HQ Dial card currently shows the crafting section inline, always visible, and has no direct link to the loadout (seat/unseat Movements and Complications) management that already exists in the bag drawer. Replace the always-inline crafting section with two buttons on the Dial card: "Adjust Loadout" (opens the existing bag-drawer loadout-management flow, unchanged — this is a navigation shortcut only, not a redesign of that flow) and "Craft Components" (opens the archetype-description-and-modal crafting menu from ticket 104). The Dial's own stats display (level, charge, capacity) at the top of the card is unaffected.

**Blocked by:** 104 — needs the archetype-description/modal crafting menu to exist as the destination for "Craft Components".

**Status:** ready-for-agent

- [ ] HQ Dial card shows "Adjust Loadout" and "Craft Components" buttons in place of the always-inline crafting section.
- [ ] "Adjust Loadout" opens the existing bag-drawer loadout-management UI, functionally unchanged from today.
- [ ] "Craft Components" opens the ticket-104 crafting menu (4 archetypes with descriptions, Craft → calc-type modal).
- [ ] Dial stats (level/charge/capacity) at the top of the card remain visible and unaffected.
- [ ] Regression test covering both buttons opening their respective flows.
