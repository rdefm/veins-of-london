# 18 — Tenure-aware daily bill

**What to build:** Each rollover, the player pays the bill for their home as ADR 0006 defines it. A rented home costs the tier's rent. An owned home costs utilities (`50 + round(0.10 × dailyCost)`). Either figure is scaled by the barometer, as today. Existing saves load as owned at their current tier; a bedsit save loads as rented. New games start in a rented bedsit.

A shortfall is still forgiven in this ticket: cash floors at 0 and no arrears accrue yet. Arrears arrive in ticket 20. The living-costs notification shows the amount actually paid, not the nominal bill.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `docs/adr/0006-property-bills-and-arrears.md` (authoritative rules, including the tenure table)
- `systems/time_system.gd` (`_apply_living_costs`, `DAILY_COST_BASE`)
- `data/home.json` (tiers)
- `autoload/GameData.gd` (home tier key validation, around the `_require_keys` for `home.tiers`)
- `autoload/GameState.gd` (`new_game_state` home dict)
- `autoload/SaveManager.gd` (load migrations)
- `scenes/phone_apps/property_app.gd` ("Daily cost" labels, which must show the tenure-correct bill)
- Tests: `tests/test_time_system.gd`, `tests/test_savemanager.gd`, `tests/test_phone_property.gd`, `tests/test_morning_accounts.gd`, `tests/test_payroll.gd`
- REFERENCE.md §1.7 `data/home.json`, §2 STATE SCHEMA (home), §3.1 Time, rest, daily tick
- CODEMAP.md, CONTEXT.md (the term *tenure*)

**Status:** ready-for-agent

- [ ] `data/home.json` carries, per tier, a buy price and a rent-only marker for the bedsit, plus the bill constants: utilities base 50, utilities fraction 0.10, interest rate 0.05, interest threshold 5 days, downgrade threshold 10 days. GameData validates them.
- [ ] The hard-coded £50 base is gone from code.
- [ ] State `home` gains `tenure` (`"rented"`/`"owned"`), `arrears` (0) and `arrearsDays` (0). These are serializable and covered by snapshot/Rewind.
- [ ] Save migration:
  - A save missing these fields gets `tenure: "owned"` (or `"rented"` at the bedsit), `arrears: 0` and `arrearsDays: 0`.
  - Re-loading a migrated save is idempotent.
- [ ] Rollover charges `round_epsilon(base × (1 + fx.dailyCost))`, where `base` is the rent if rented and the utilities if owned. Tests cover these ADR examples: rented flat 80; owned townhouse 65; rented flat under inflation 104.
- [ ] The notification and bank log both state the amount actually paid. "Flat broke" behaviour is unchanged.
- [ ] Property app "Daily cost" shows the bill for the player's tenure.
- [ ] REFERENCE.md §1.7/§2/§3.1, CONTEXT.md and CODEMAP.md are updated to match.
- [ ] Syntax check clean, full suite passes.
