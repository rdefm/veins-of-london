# 06 — Contract counterparty + delivery hook

**What to build:** Every offer and contract names the faction it's with, shown on offer and active-contract cards. Scripted templates (`biz_starter_*`, `biz_recurring_*`, `scripted_*`) declare `counterparty` in offers data. Random offers: if offer value is under a size threshold (JSON), counterparty ∈ {collective, firm} by identity fit (life/emotion → Collective, physics → Firm; otherwise the one with higher player relation, ties via seeded Rng). Above the threshold: weighted across all five — ore goods toward factions that craft with that ore, item goods toward factions that consume it; no weight → small-offer rule. Old saves backfill counterparty by the same rule (scripted from data). Each contract delivery calls `Market.note_contract_delivery(counterparty, kind, type, qty)`, which records the delivery (bounded) with no supply record and no price effect — the seam sub-spec 2 fills. Spec §Contracts / Offers "Counterparty", "Delivery hook".

**Blocked by:** 01 — Market core; 05 — Faction economic identity data.

**Relevant files:**
- `systems/offers.gd` (`create_offer`, `create_scripted_offer`, `accept_offer`), `systems/contracts.gd` (delivery path)
- `systems/market.gd` (`note_contract_delivery`, `deliveries[]`)
- `data/offers.json` (per-template `counterparty`, small-offer threshold)
- `scenes/phone_apps/bizbrief_app.gd` (offer + active cards)
- `autoload/SaveManager.gd` (backfill)
- Tests: `tests/test_offers.gd`, `test_contracts.gd`, `test_savemanager.gd`, `test_business_quest.gd`
- `docs/REFERENCE.md` §3.10 (contracts: counterparty); CODEMAP offers/contracts rows if responsibility changes

**Status:** ready-for-agent

- [ ] Small offers: life/emotion → Collective, physics → Firm, otherwise higher-relation of the two (seeded tie-break)
- [ ] Large offers weighted by identity; no-weight goods fall back to the small rule
- [ ] Scripted templates carry their authored counterparty
- [ ] Old-save offers/contracts get a counterparty on load
- [ ] Delivery records into `market.deliveries` and leaves supply tallies untouched
- [ ] Cards show the counterparty; PROSE-REVIEW on the card line
- [ ] REFERENCE.md §3.10 updated
