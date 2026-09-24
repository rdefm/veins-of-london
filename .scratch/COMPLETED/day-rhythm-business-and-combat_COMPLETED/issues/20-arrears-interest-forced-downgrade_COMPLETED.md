# 20 — Arrears, interest and forced downgrade

**What to build:** A bill the player can't cover now becomes **arrears** instead of being forgiven. Each rollover's living-costs step runs in the ADR 0006 order:

1. If in arrears for ≥ 5 days, add 5% compounding interest.
2. Pay the arrears from cash.
3. Pay today's bill. Any remainder is added to arrears.
4. Advance the unpaid-day clock. It resets only when arrears reach £0.
5. At 10 days, if the home is not the bedsit, force a one-tier downgrade using ticket 19's tier-change operation. The new tier is rented.
   - Owned tier: arrears are cleared.
   - Rented tier: arrears are kept.
   - The clock restarts either way.

At the bedsit, arrears and interest keep accruing and nothing further happens. Wages are paid afterwards from whatever cash is left.

**Blocked by:** 18 — Tenure-aware daily bill; 19 — Rent/buy tier moves

**Relevant files:**
- `docs/adr/0006-property-bills-and-arrears.md` (Daily ordering, Worked examples)
- `systems/time_system.gd` (`_apply_living_costs`, `daily_tick` ordering)
- `systems/home.gd` (tier-change operation from 19)
- `systems/payroll.gd` (must still run after, from remaining cash)
- `systems/bank.gd` (logging of arrears payments)
- Tests: `tests/test_time_system.gd`, `tests/test_payroll.gd`, `tests/test_home.gd`
- REFERENCE.md §3.1 Time, rest, daily tick (step ③); M0-PORT.md `cash ≥ 0` invariant
- CODEMAP.md (`time_system.gd` row)

**Status:** ready-for-agent

- [ ] Tests reproduce every ADR worked example:
  - Zero and partial cash, where a partial payment doesn't reset the clock.
  - The rented-flat 10-rollover table (ends: bedsit, arrears 953, days 0).
  - The owned-flat table (ends: bedsit, arrears 0).
  - Both recovery cases (still 170 in arrears; fully cleared with cash 130).
  - The exact-affordability boundary.
- [ ] Interest first applies on the 6th consecutive rollover in arrears and uses `round_epsilon`. The barometer never scales arrears or interest.
- [ ] Forced downgrade applies ticket 19's room wipe, staff unassign, gym revert and security loss. It never fires at the bedsit.
- [ ] Cash never goes negative. Wages come from the cash left after the bill.
- [ ] Notifications state the amount paid and any shortfall added to arrears. A forced downgrade gets its own warning notification. New strings are flagged PROSE-REVIEW.
- [ ] The Rewind/snapshot round-trip restores arrears, clock and tenure exactly.
- [ ] REFERENCE.md §3.1 step ③ is rewritten to the approved order. CODEMAP.md is updated.
- [ ] Syntax check clean, full suite passes.
