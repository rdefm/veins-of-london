# 09 — Sales calc purchases (buyCalc)

**What to build:** Beside each delegated contract, a switch lets Archie buy missing calc from the cheapest source available to the player, paid from the pot. He buys only the shortfall, spills to the next-cheapest lane when one runs dry, skips any purchase the pot can't cover in full, and records it as a `calc` expense for the week. Bought ore enters shared stock and triggers normal delivery.

**Blocked by:** 04 — Business pot and payday

**Relevant files:** `systems/contracts.gd` (Sales delivery check), `systems/factions.gd` (faction buy price / max quantity), `data/faction_trade.json` (lane order), `systems/business.gd`, `systems/rooms.gd` (producer per-unit calc cost), `scenes/bizbrief_app.gd` (Manage → Sales), `tests/test_contracts.gd`, `tests/test_factions.gd`; spec §"Business pot and payday" (Calc purchases), Further Notes (no district modifier).

**Status:** ready-for-agent

- [ ] Per-contract `buyCalc` toggle via a system setter; UI in Manage → Sales on delegated contracts only
- [ ] Shortfall: ore = remaining qty − shared stock; crafted = remaining units × per-unit calc cost of the lowest-cost current producer − shared stock of that ore
- [ ] Candidates: every ore-selling lane the player can currently buy from, ranked by unit price (relation discounts via existing functions), ties by lane order; no district modifier regardless of lane setting
- [ ] Spill over to next-cheapest when quantity insufficient; stock/relation side effects identical to player buying that lane
- [ ] Pot can't cover the full purchase → skipped entirely; player cash never touched
- [ ] Recorded as a `calc` expense naming the source
- [ ] Tests: cheapest lane + spill-over; unaffordable skip
- [ ] CODEMAP.md updated; on-device QA block for the toggle
