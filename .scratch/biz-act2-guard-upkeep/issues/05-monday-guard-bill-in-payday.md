# 05 — Monday guard bill inside payday (pot active)

**What to build:** While the pot is active, the Monday guard bill is paid inside the business payday, never from player cash.

- **Order:**
  1. Staff wages, with the float as backup (from 04).
  2. The guard bill, drawing the pot first, then the float.
  3. The partner split, on whatever pot remains.
- **Recording:** guard wages are business expenses of kind `guard` (vein id or `home`). They appear in the week's expense list, the payday ledger record, BusinessStats and the guard cost history.
- **Short bill:** if pot and float together can't cover the bill, all pot and float money available for guards is set aside as a guard wage reserve. It's removed from the pot and float and not split. The payday returns a "short" result carrying the reserve, for ticket 06 to act on.
- The pre-pot path from 03 is unchanged.

**Blocked by:** 03 — Monday guard bill, before the pot exists; 04 — Business float.

**Relevant files:**
- `systems/business.gd` (`_payday`, ledger record, split), `systems/guard_upkeep.gd`, `systems/time_system.gd`
- `systems/business_stats.gd`, `systems/morning_accounts.gd` (payday statement)
- `tests/test_business.gd`, `tests/test_guard_upkeep.gd`, `tests/test_time_system.gd`
- Spec §Player Monday bill (pot active); REFERENCE.md §3.1, §3.10

**Status:** ready-for-agent

- [ ] Pot active and covering everything: staff are paid, then guards, then the split runs on the remainder; cash untouched
- [ ] Pot short but pot and float together cover it: the float pays the rest of the guard bill and is never split
- [ ] Staff wages come before guards when money is short
- [ ] Guard expenses appear as kind `guard` per place in the week's expenses, the ledger, BusinessStats and history
- [ ] Pot and float together short: the reserve is set aside (pot and float reduced by it), a "short" result is returned, and the partner split runs on what remains
- [ ] The payday statement / morning account shows guard wages paid (PROSE-REVIEW)
- [ ] REFERENCE §3.1 and §3.10 updated
