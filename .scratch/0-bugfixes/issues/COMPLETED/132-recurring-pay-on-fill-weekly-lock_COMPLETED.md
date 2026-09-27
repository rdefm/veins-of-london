# 132 — Recurring contracts: pay on fill, lock until Monday, explain delegation

**What to build:** A recurring contract's period is one calendar week (Mon–Sun). As soon as its quota is fully delivered — manually, or automatically when delegated — it pays out immediately. Deliveries are then locked until the next Monday, when a fresh period opens. The due day doesn't move forward and there's no second payout that week. This fixes the current bug where you can deliver again and again, get paid every time, and push the due day later. If a period isn't filled by Monday, the current miss/partial settlement stays as it is. Auto-delivery still only happens for delegated contracts. The card spells out what delegating needs (staffed Sales + the delegate toggle + the Beat 7 unlock) and shows whether this contract is delegated right now. A filled period's card shows "Delivered this week — next period MON d MMM".

**Blocked by:** 130 — Monday cadence.

**Relevant files:** `systems/contracts.gd` (`deliver`, `settle`, renewal, `shared_stock_increased`, `process_delegated_deliveries`, `has_staffed_sales`, `set_delegated`), `scenes/components/contract_card.gd`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_contracts.gd`; REFERENCE.md §3.10 "Unattended proof", "Staff roles".

**Status:** ready-for-agent

- [ ] Manually filling a recurring period pays once and blocks further deliveries until Monday; tested
- [ ] A delegated contract auto-fills and pays as soon as shared stock covers it, then locks; tested
- [ ] The Monday rollover opens the new period; an unfilled period settles as before; tested
- [ ] `qualified` / Unattended proof and the Beat 7 objectives still work (existing business_quest tests green)
- [ ] Card shows delegation requirements/status and the filled-this-week state
- [ ] PROSE-REVIEW: delegation explainer copy
- [ ] Human on-device: deliver a weekly contract, confirm the button locks and the card shows the next period date
