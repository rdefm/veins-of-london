# 01 — Fully delivered contract settles immediately; delivery costs no time

**What to build:** When a manual delivery in BizBrief leaves a contract with nothing remaining, the contract settles right away: the player is paid the full quote. A one-off contract then disappears from the active list. A recurring contract stays, and its current period closes and renews through the existing settle path, so the due-day tick never pays it twice. Manual delivery (Deliver 1 / Deliver all) no longer costs a time block.

Playtest repro: accept a contract, tap Deliver all with enough stock. The stock is taken, but the contract stays active and no payment ever arrives, even after days pass.

Cause (found during triage): `ContractsSystem.deliver()` only records the delivered quantities. Payment happens only in `settle()`, which runs from `daily_tick()` once `dueDay` is reached. `deliver()` also calls `TimeSystem.advance_time_block()` when `consume_time` is true.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/contracts.gd` (`deliver`, `settle`, `daily_tick`, `is_complete`, `_deliver_delegated`)
- `scenes/phone_apps/bizbrief_app.gd` (Deliver 1 / Deliver all buttons, any time-cost labels)
- `.scratch/day-rhythm-business-and-combat/business-spec.md` §Fulfilment and settlement (update: manual delivery is free, and full delivery settles immediately)
- `tests/test_contracts.gd`

**Status:** ready-for-agent

- [ ] Manual delivery that completes a one-off contract pays the full quote at once, records a settlement, and removes the contract from the active list and the priority order
- [ ] Manual delivery that completes a recurring contract's period pays at once and renews the period (delivered reset, next dueDay). The later daily tick does not pay that period again
- [ ] Partial manual delivery does not settle; deadline settlement for incomplete contracts is unchanged
- [ ] Manual delivery no longer advances time, and BizBrief no longer shows a time cost on delivery buttons
- [ ] Delegated (Sales) delivery keeps working and uses the same immediate-settle path when it completes a period
- [ ] business-spec.md updated to match; tests cover one-off, recurring, partial, and no-time-cost
