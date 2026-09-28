# 05 — Contract deliveries → buyer holdings + supplier share

**What to build:** Each contract delivery (already noted via `note_contract_delivery`) now adds the delivered goods to the buyer faction's holdings and credits the player's supplier share with that faction. It records no Market supply and no ore/crafting share (no double count). That a delivery reduces the faction's next London buy is asserted in 11, once buying exists.

Spec: §Contract deliveries, §Shares.

**Blocked by:** 01 — Faction holdings + real shops; 04 — Shares core.

**Relevant files:**
- `systems/market.gd` (`note_contract_delivery`), `systems/contracts.gd` (delivery path), `systems/shares.gd`
- Tests: `tests/test_contracts.gd`, offers delivery tests, `tests/test_shares.gd`
- REFERENCE.md §3.10, §3.13 "Deliveries"

**Supplier share decision (2026-09-28, human):** record and show BOTH reads, per faction, over the 7-day window:
- **A — delivery split:** player deliveries to faction F ÷ all player contract deliveries ("where my output goes").
- **B — intake share:** player deliveries to F ÷ F's total intake (player deliveries + F's London buys) ("how dependent F is on me"). Needs a per-faction London-buy tally in Shares, recorded by ticket 11's buying.
- Unit for both: ore-equivalent (calc 1:1; items count recipe ingredient weights).
Ticket 04 stores only the delivery tally (`Shares.record_delivery`); the reads land in 05, the buy tally in 11, display in 15.

**Status:** ready-for-agent

- [ ] A delivery lands in the buyer faction's holdings
- [ ] A delivery credits the player's supplier share for that faction
- [ ] A delivery adds no ore share and no Market supply
- [ ] REFERENCE.md updated
