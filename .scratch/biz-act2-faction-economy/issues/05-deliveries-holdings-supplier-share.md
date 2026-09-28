# 05 — Contract deliveries → buyer holdings + supplier share

**What to build:** Each contract delivery (already noted via `note_contract_delivery`) now adds the delivered goods to the buyer faction's holdings and credits the player's supplier share with that faction. It records no Market supply and no ore/crafting share (no double count). That a delivery reduces the faction's next London buy is asserted in 11, once buying exists.

Spec: §Contract deliveries, §Shares.

**Blocked by:** 01 — Faction holdings + real shops; 04 — Shares core.

**Relevant files:**
- `systems/market.gd` (`note_contract_delivery`), `systems/contracts.gd` (delivery path), `systems/shares.gd`
- Tests: `tests/test_contracts.gd`, offers delivery tests, `tests/test_shares.gd`
- REFERENCE.md §3.10, §3.13 "Deliveries"

**Status:** ready-for-agent

- [ ] A delivery lands in the buyer faction's holdings
- [ ] A delivery credits the player's supplier share for that faction
- [ ] A delivery adds no ore share and no Market supply
- [ ] REFERENCE.md updated
