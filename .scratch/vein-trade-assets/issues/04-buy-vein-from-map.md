# 04 — Buy a faction-owned vein directly from the map

**What to build:** Two more entry points into the same buy-a-vein mechanism
ticket 03 built, both reachable without going through a contact
conversation at all:

1. The map's per-site detail sheet already shows a faction-owned vein's
   card with a Raid button on it when you tap that site. Add a "Buy — £X"
   button alongside Raid, for any faction vein whose owning faction
   currently has vein trading unlocked.
2. Tapping a district and choosing to view its veins already lists each
   site as a row with a "View" button. Add a matching "Buy — £X" button on
   any row currently showing a buyable faction vein, so buying doesn't
   require opening the full site sheet first.

Both buttons call the exact same buy function and pricing ticket 03
introduced — no separate pricing logic, no separate side-effect handling.
Same rules as the modal path: free/unconditional (no time-block cost), gated
by the same vein-sale-unlocked flag.

**Blocked by:** 03 — needs the buy function to exist.

**Status:** ready-for-agent

- [ ] The site detail sheet shows a "Buy — £X" button next to Raid for any
      faction vein currently eligible to buy, using the same price the
      Trade modal would quote for the same vein.
- [ ] The district vein-list panel shows a matching "Buy — £X" button next
      to View on each eligible site row.
- [ ] Both buttons invoke the same underlying buy mechanism from ticket 03
      — confirm there's no duplicated pricing or bookkeeping logic between
      the three surfaces (modal, site sheet, district row).
- [ ] Buying from either map surface costs cash only, no time block.
- [ ] A site/vein not eligible to buy (faction not unlocked, or not
      faction-owned) shows neither button — no disabled/greyed state, same
      "just don't show it" convention the rest of the map screen already
      uses for ungated actions.
