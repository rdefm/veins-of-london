# 05 — Assay commissions: rank = player's highest or highest+1

**What to build:** Assay commissions should track the player's own crafting level for the requested item, not the Guild perk tier. Remove `rankFloors`. Each commission's `minTier` is, 50/50:
- the player's best rank for that item, or
- best rank + 1, offered even if that rank isn't unlocked yet, to encourage growth.

Cap it at the game's max rank. If the player has no rank in the item (unknown recipe), use rank 1 or 1+1 by the same 50/50. The item is picked with ticket 04's ramp (known-weighted early, fully random by day 30), not "any Lab-known recipe". Update REFERENCE.md "Assay commissions".

**Blocked by:** 04 — Offer variety (shared ramp helper).

**Relevant files:** `systems/offers.gd` (`create_assay_commission`, `assay_rank_floor`), `data/offers.json` (`assay`), `systems/lab.gd` (best rank), `systems/recipe_knowledge.gd` (`rank_ceiling`), `docs/REFERENCE.md` §3.10 "Assay commissions"

**Status:** ready-for-agent

- [ ] `rankFloors` and the Guild-tier lookup are gone
- [ ] minTier is best or best+1 (50/50, seeded test), capped at the max rank
- [ ] +1 is offered even when that rank is locked
- [ ] Item pick uses ticket 04's ramp
- [ ] REFERENCE.md updated
