# 04 — Business float

**What to build:** Once the business pot is active, the player can donate cash into a reserve float and withdraw it at any time.

- **Donate** moves between £1 and all of the player's cash into `business.float`. It's refused before the pot is active.
- **Withdraw** moves between £1 and the whole float back to cash.
- Both leave bank records, and neither counts as business revenue.
- **Payday never splits the float.**
- **Backup draws.** The float is only drawn when the pot can't cover a bill:
  - Staff wages: still paid in full or not at all per contact. The existing owed-wage prompt is unchanged.
  - Sales calc purchases: pot and float together, still all-or-nothing.
- **Display:** the BizBrief Brief bank block shows the float beside the pot, with Donate and Withdraw controls.

**Blocked by:** None — can start immediately. Doing 01 first helps, so the calc and staff expense kinds are already split.

**Relevant files:**
- `systems/business.gd` (`daily_tick`, `_payday`, `pay_calc_purchase`, owed wages), `systems/bank.gd`, `systems/business_stats.gd`
- `scenes/phone_apps/bizbrief_app.gd` (Brief tab bank block)
- `autoload/GameState.gd`, `autoload/SaveManager.gd` (backfill `business.float` = 0)
- `tests/test_business.gd`, `tests/test_savemanager.gd`
- CODEMAP.md
- Spec §Business float; REFERENCE.md §2, §3.10

**Status:** done

- [x] `Business.donate` / `Business.withdraw` enforce their bounds, write bank records, and don't count as revenue
- [x] Donate is refused while the pot is inactive
- [x] The payday split ignores the float
- [x] A staff wage the pot can't cover is paid from the float if pot and float together cover it; otherwise it's owed as today
- [x] `pay_calc_purchase` succeeds using pot and float together, and takes nothing if both together are short
- [x] `business.float` is backfilled to 0, survives save/load, and Rewind restores it
- [x] The Brief bank block shows the float with Donate/Withdraw (PROSE-REVIEW any new strings)
- [x] REFERENCE §2 and §3.10 updated; CODEMAP updated

**Human QA on device:**
- The BizBrief Brief bank block shows the Float next to the Pot.
- Donate and Withdraw work, and are hidden or disabled before the pot is active.
