# 07 — New game soft-locks: Archie's opening chain never lets the player proceed

**What to build:** Starting a brand-new game (not debug start) and playing through the opening dialogue/text exchange with Archie: the chain ends with no way to close it or move to the next beat. Since this happens before `archiePartnerSeen` is set, the nav bar's Map tab is also still locked ("Stick close for now — Archie"), so the player is left with no path forward at all — a full soft-lock on a fresh install.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Play a genuinely new game from scratch (not debug start) through the opening Archie sequence — it reaches a point that sets `archiePartnerSeen` and hands control back to the player (nav unlocked, no dead-end screen) without manual intervention.
- [ ] Confirm which exact screen/flow dead-ends today (the intro event, the home-raid sequence, or an SMS thread) and fix the actual break — don't just add an escape hatch on top of a still-broken chain.
- [ ] Existing playthrough/event tests still pass; add a regression check if the current test suite doesn't already drive a genuinely-fresh (non-debug-start) new game through this sequence.
