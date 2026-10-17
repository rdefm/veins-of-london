# 09 — Assay commissions

**What to build:** Repeatable Guild assay commissions from Wren, as a new offer kind in the existing offers pipeline: "deliver N × recipe at rank/tier ≥ R by day D". They pay cash plus Guild faction relation. They are generated only once Wren's commissions flag is set (set by `wren_introduction`; tests set it directly). R scales with the Guild perk tier: Stranger / Friendly / Partner / Sworn map to rank floors in data. Commissions use existing offer expiry and pending caps. Delivery takes only items of tier ≥ R from inventory. Existing Guild relation sources, including the Sworn `guild_commissions` perk, keep working unchanged.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Assay commissions"; § User Stories 58–61; § Testing Decisions Seam 3.

**Blocked by:** 02 — Sellers, gates, prices and buying knowledge. (Needs only the commissions flag, defined here if 08 hasn't landed; 08 sets it.)

**Relevant files:**
- `systems/offers.gd` (next to `_maybe_guild_commission`, `_commission_request`), `data/offers.json`
- `systems/contracts.gd` (delivery / fulfilment), `systems/crafting.gd` (`inventory_remove_from_tier`, tiered buckets)
- `systems/perks.gd` (`player_tier`), `systems/factions.gd` (relation)
- `scenes/components/contact_cards.gd` / offer UI rows (only if the new kind needs a label)
- `tests/test_offers.gd`, `tests/test_contracts.gd`
- `CODEMAP.md` (offers rows); `docs/REFERENCE.md` — § assay commissions

**Status:** ready-for-agent

- [ ] No assay commissions generated before the flag; generated after it.
- [ ] Rank floor follows the Guild tier (test each tier).
- [ ] Delivery accepts items at tier ≥ R only, and removes them from the correct tiers.
- [ ] Payout = cash + Guild relation.
- [ ] Expires through existing offer expiry and respects pending caps.
- [ ] Existing Sworn commission and other Guild relation tests unchanged.
- [ ] PROSE-REVIEW: commission text.
