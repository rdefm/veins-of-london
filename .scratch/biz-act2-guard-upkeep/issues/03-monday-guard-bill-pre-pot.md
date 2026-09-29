# 03 — Monday guard bill, before the pot exists

**What to build:** On the rollover into a Monday, every guard on duty (all player vein guards plus HQ guards) is paid `weeklyWage` in advance for the week ahead.

- **Pot not active:**
  - The bill comes from player cash, with a "Guard wages" bank record, if cash covers it in full.
  - Each place's share goes into the guard cost history and into BusinessStats as a guard expense.
- **Notice:** the Monday notification and morning account say what the guards were paid.
- **Guards that are gone aren't billed**, and there are no refunds. That covers guards on veins the player no longer owns (sold, raided away, collapsed, bought out) and HQ guards lost to a tier move below `minTier`.
- **Old saves** are first billed on the next Monday. Nothing builds up between Mondays, so there are no per-guard counters.
- **Short cash:** nothing is taken and the rollover returns a "short" result for ticket 06 to act on. Until 06 lands, guards are left untouched.
- **Where it runs:** a new guard upkeep system, called from the rollover's step-⑥ slot. The exact step letter is fixed in REFERENCE §3.1.

**Blocked by:** 02 — Guards are hired.

**Relevant files:**
- new `systems/guard_upkeep.gd`; `systems/time_system.gd` (daily tick, ⑥ slot near `Payroll.pay_wages`)
- `systems/calendar.gd` (`is_monday`), `systems/bank.gd`, `systems/business_stats.gd`, `systems/morning_accounts.gd`, `systems/notify.gd`
- `systems/home.gd` (`change_tier` guard loss), `systems/vein_trade.gd`, `systems/raiding.gd` (vein loss paths — check guards leave with the vein)
- `tests/test_time_system.gd`, `tests/test_home.gd`, new `tests/test_guard_upkeep.gd`
- CODEMAP.md
- Spec §Weekly wage, §Player Monday bill (pot not active), §Rollover order; REFERENCE.md §3.1

**Status:** ready-for-agent

- [ ] On a Monday rollover with the pot inactive, cash drops by 500 × (vein guards + HQ guards), with a "Guard wages" bank record
- [ ] Non-Monday rollovers bill nothing
- [ ] Per-place history and a BusinessStats guard expense are recorded
- [ ] Guards on a sold or lost vein, and HQ guards lost to a tier move, aren't billed; no refunds
- [ ] An old save loaded midweek isn't billed until the next Monday
- [ ] Short cash: nothing taken, a "short" result returned, guards unchanged
- [ ] The Monday notification and morning account carry the paid line (PROSE-REVIEW)
- [ ] REFERENCE §3.1 step fixed; CODEMAP updated
