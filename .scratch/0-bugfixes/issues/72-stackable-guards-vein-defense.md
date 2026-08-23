# 72 — Stackable "guards" vein defense past the security ladder cap

**What to build:** Vein security today is a hard-capped 4-tier ladder (unsecured → basic → warded → guarded) with no way to invest further once "guarded" is reached — meaning even the player's richest, highest-terroir veins (now the most attractive claim targets per ticket 70) can't out-invest their takeover risk beyond that ceiling. Once a vein reaches "guarded," the same upgrade button should become a repeatable purchase that keeps adding defensive strength, with no hard cap, so a well-funded player can keep buying down their raid risk on their best veins.

**Blocked by:** 70 (raises the ceiling the new terroir-scaled claim formula divides against — sequencing after avoids reworking that formula twice).

**Status:** ready-for-agent

- [ ] Once a vein's security reaches "guarded," its upgrade button becomes a repeatable "+1 Guard" action rather than being disabled — same UI element, not a separate menu entry.
- [ ] Each additional guard adds to the vein's raid-resistance stat with no upper limit.
- [ ] Cost scales up per additional guard purchased on that vein (**needs balance sign-off** — propose an escalating cost curve on top of the existing 0/20/60/120 ladder pricing).
- [ ] The raid-resistance formulas that currently divide against the old fixed ceiling (player-raids-faction stealth odds, faction-raids-player claim odds, faction rivalry odds) are updated to scale correctly with an uncapped value rather than assuming a fixed maximum.
- [ ] `docs/REFERENCE.md` updated to describe the stackable guard mechanic and its cost curve.
- [ ] Test coverage: purchasing guards past "guarded" continues to reduce raid-success odds with no ceiling; cost increases per guard purchased.
- [ ] Manual check noted for the human: buy several guards past "guarded" on a vein and confirm the security UI and raid odds behave sensibly at high guard counts.
