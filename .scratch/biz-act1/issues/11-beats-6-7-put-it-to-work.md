# 11 — Beats 6–7: put it to work

**What to build:** Archie demonstrates a recurring order and unlocks delegation. The scene issues a guaranteed weekly Time Pearl order plus a choice of weekly time-ore or life-ore orders. The goal completes when two distinct recurring contracts each have a qualifying unattended period (at least one requesting a crafted item). A closing scene reads the latest payday record — both completed periods, Owen's wage, the three-way payout, Archie excited, James grudgingly approving — and the act completes; the operation keeps running.

**Blocked by:** 08 — Beats 4–5; 09 — Sales calc purchases; 10 — Unattended-proof taint

**Relevant files:** `systems/offers.gd`, `systems/contracts.gd` (`set_delegated`, delegation gate), `systems/objectives.gd`, `systems/todo.gd`, `systems/business.gd` (ledger), `data/offers.json`, `data/objectives.json`, `data/events/`, `tests/test_offers.gd`, `tests/test_objectives.gd`; spec §"Starter and recurring offer catalogue", §"Questline and objectives" (Beats 6–7), Further Notes (balance check).

**Status:** ready-for-agent

- [ ] Templates `biz_recurring_time_pearl` (timePearl ×5), `biz_recurring_time_ore` (time ore ×6), `biz_recurring_life_ore` (life ore ×6), weekly
- [ ] Beat 6 offers don't expire while Beat 6 unmet; declined → reissued next day; pending cap of 4 respected (reissue waits)
- [ ] Delegation gated on the Beat 6 flag
- [ ] Beat 6 evaluator: ≥ 2 distinct contract ids with ≥ 1 qualified settlement, ≥ 1 a crafted request; need not qualify same week; pre-existing delegated recurring contracts count
- [ ] Beat 7 closing scene reads latest ledger record; act-complete flag; staff and pot keep running after
- [ ] ToDo reflects Beats 6–7
- [ ] Test: Sales calc purchases don't disqualify
- [ ] New prose flagged `PROSE-REVIEW:`; CODEMAP.md updated
