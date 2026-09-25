# 04 — Business pot and payday

**What to build:** A new Business system holds a pot of business money. While the pot is active, every BizBrief contract settlement pays into the pot instead of the player. Every seventh day, payday pays Owen's weekly wage (prorated first week, plus anything owed), then splits the remainder three ways (player, Archie, James; rounding to the player), credits the player's share with a bank record, empties the pot and writes a ledger entry. If the pot can't cover Owen, he goes unpaid and stops working until paid in full; the morning BizBrief offers to pay from the player's cash, and a Pay now action is available while he's owed. The payday Morning Brief shows receipts, expenses and shares.

**Blocked by:** 01 — Founder roles, skill caps, Owen roster, save fix-ups

**Relevant files:** new `systems/business.gd`, `autoload/GameState.gd` (new `business` subtree), `systems/contracts.gd` (settlement), `systems/time_system.gd` (rollover order), `systems/bank.gd`, `systems/morning_accounts.gd`, `scenes/bizbrief_app.gd` (Brief tab), `data/constants.json`, `tests/test_contracts.gd`, `tests/test_morning_accounts.gd`, `tests/test_phone_bizbrief.gd`; REFERENCE.md §2 STATE SCHEMA; spec §"Business pot and payday".

**Status:** ready-for-agent

- [ ] `business` subtree per the spec schema (pure data): `potActive`, `pot`, `week`, `partners`, `wages.owen`, `ledger`, `nextPaydayId`
- [ ] A public activation call (used by Beat 3) sets `potActive`, partners `["archie","james"]`, Owen's `hiredDay`
- [ ] Routing decided by settle day: pot + `week.receipts` while active, player cash otherwise; sales outside BizBrief never routed
- [ ] Payday at the rollover where `day % 7 == 0`, after due settlements
- [ ] Wage due = `round(250 × daysWorkedThisWeek / 7)` for first partial week, plus `owed`; no accrual while unpaid; 250 is data
- [ ] Shortfall → `owed`, `unpaid = true` (staff step skips Owen); morning prompt "Pay Owen from your own cash?"; Yes pays from cash and resumes; No leaves him unpaid
- [ ] Each later rollover retries owed from the pot; Pay now (player cash) available while owed; full payment resumes him
- [ ] Split: partner share `floor(R/3)`, player `R − 2 × floor(R/3)`; player share → cash + bank record; partner shares leave the game; pot → 0; ledger record; new week
- [ ] Idempotent: stable payday ids, record written before cash moves
- [ ] Morning Brief payday statement: receipts, expense lines (wage, calc), three shares
- [ ] Pure checks: split rounding, prorated wage. Scenario: declined prompt stops Owen, later full payment resumes him
- [ ] REFERENCE.md §2 and CODEMAP.md updated; on-device QA block for Brief statement/prompt
