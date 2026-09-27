# 147 — Contracts auto-deliver on each time block (delegation removed)

**What to build:** Delegating contracts to Sales is removed; delivery is fully automatic. While a Sales contact is assigned and working (paid), every active contract is delivered from shared stock — unstashed ore and crafted items, less Production's reserve; never the player's personal stash — at each time-block advance (after the staff block). Nothing delivers mid-block, so ore/items the player crafts, cultivates or unstashes are not taken immediately: the player has until the next block to stash them. Fully-coverable periods close first, then partials in priority order. Recurring period locking, settlement and the per-contract "buy calc shortfall" toggle stay (the toggle now applies to every contract). Removed: the delegate toggle and status, manual Deliver, the `delegated`/`delegatedWholePeriod` fields, the Beat 7 delegation gate, and immediate delivery on stock increase. Old saves drop the removed fields on load. The Beat 7 objective/scene follow ticket 148's decision.

**Blocked by:** 148 — Rewrite Beat 7 now that delegation is gone.

**Relevant files:** `systems/contracts.gd` (`DELEGATION_FLAG`, `delegation_status`, `set_delegated`, `set_buy_calc`, `start_period`, `note_player_supplied`, `note_player_tended_vein`, `_period_qualifies`, `shared_stock_increased`, `process_delegated_deliveries`, `deliver`, `_deliver_delegated`, `_buy_calc_shortfalls`, `_shared_stock_for_line`), `systems/time_system.gd` (`advance_time_block`, `daily_tick` ⑥.3), `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/contract_card.gd`, `systems/business_quest.gd` (~L165-172), `systems/objectives.gd` (~L300), `systems/crafting.gd`, `systems/stash.gd`, `autoload/SaveManager.gd`, `CODEMAP.md` (contracts.gd row); REFERENCE.md §2 `sales` schema, §3.10 "Unattended proof" + Beats 6-8; `docs/biz-act1-vision.md`.

**Status:** ready-for-agent

- [ ] With Sales staffed, a block advance delivers coverable contracts; tested
- [ ] Crafting/cultivating/unstashing mid-block delivers nothing until the next advance; tested
- [ ] Unassigned or unpaid Sales delivers nothing; tested
- [ ] Stashed ore/items are never taken; Production reserve respected; tested
- [ ] Partial delivery by priority; recurring lock + settlement unchanged; tested
- [ ] buyCalc works on any contract; tested
- [ ] No delegate toggle, status or Deliver button left in BizBrief
- [ ] Old saves load without delegation fields; tested
- [ ] CODEMAP + REFERENCE updated
- [ ] Human on-device: accept a contract with stock on hand, advance a block — it delivers; craft, stash before advancing — stashed items stay
