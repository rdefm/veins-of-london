# Site lifecycle: `siteCap`, NPC-claim eligibility, and abandonment

D2's original text left the interaction between `siteCap`, NPC-claimed sites, and the prospect re-roll mechanic underspecified: NPC-claimed sites keep `claimed: false` (only `npcClaimed` flips), so it was ambiguous whether they counted toward `siteCap`, were eligible to be deleted by the "reroll worst unclaimed site" rule, or were seedable by the player. Left as written, a district could also end up permanently locked once its `siteCap` slots filled with a mix of player- and NPC-claims, with no unclaimed site left to reroll — good land would be gone forever.

**Decisions:**
- `siteCap` counts every site in the district regardless of state (unclaimed + player-claimed + NPC-claimed) — the original literal reading of "max concurrent unclaimed+claimed sites."
- NPC-claimed sites are untouchable: never eligible for the prospect re-roll, never seedable by the player in M1 (reclaiming one is M2 combat content, per D2's existing note).
- **New mechanic — NPC abandonment**, a daily-tick step alongside D2's existing NPC-claim step (⑤b): for each NPC-claimed site, `p = 0.05 + 0.01 × ageDaysSinceNpcClaim` (capped `0.15`), flat across tiers (no richness weighting — claims aren't stickier just because the land is good). On hit, the site is **deleted outright** (not reverted to unclaimed) — this frees a `siteCap` slot; the next prospect in that district rolls a brand-new site from scratch rather than the old one reappearing with its original tier/ore/bonuses. Deletion (vs. reversion) was chosen deliberately so "wait out the good NPC-claimed site" isn't a viable strategy — the plot is gone, not dormant.
- Schema addition needed: site dict gains `npcClaimedDay: int|null`, set when the NPC-claim tick fires, to compute `ageDaysSinceNpcClaim`.

**Status:** accepted (2026-07-30, during `/grill-with-docs` session on `plans/M1-LONDON.md`).
