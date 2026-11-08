# 03 — Production target split from Keep

**What to build:** Make Production, Keep and Sell-above three distinct numbers. Staff craft until stock reaches Production (plus summed undelivered contract need while Cover contracts is on). Keep becomes a plain never-sell floor and is the personal reserve that contract delivery may not draw from (replacing the old personal target in that role). Auto-sell's protected floor becomes `max(Sell-above, Keep, contract need while covering)`. Keep must be strictly below Sell-above, enforced in the system for master and overrides (raising Keep pushes Sell-above up; lowering Sell-above stops above Keep; clamped to `productionTargetMax`). Production is unconstrained in 0..`productionTargetMax`. The current Production row gains a minimal Production control so the split is checkable on-device before the UI rebuild.

**Blocked by:** 02 — Master + override production settings model.

**Relevant files:** `systems/rooms.gd` (producer step, `effective_lab_target`, `contract_need`); `systems/auto_sell.gd` (`protected_floor`, `_assess`, `projection`, setters); `systems/contracts.gd` (`_shared_stock` reserve); `systems/morning_accounts.gd`; `scenes/phone_apps/bizbrief_app.gd` (`_build_production_recipe_row`, `_target_text`, `_show_contract_hold`); `scenes/ui/stock_bar.gd`; `tests/test_rooms.gd`, `tests/test_auto_sell.gd`, `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §3.6 "Auto-sell" (Protected floor, Controls), §3.10 Producer (effective target, personal-target reserve); `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Producers craft to Production (+ contract need when covering), independent of Keep.
- [ ] Contract delivery never draws stock at or below Keep.
- [ ] Auto-sell never sells at or below `max(Sell-above, Keep, contract need if covering)`.
- [ ] Keep < Sell-above holds after every setter call (master and override); Production clamps only to 0..max.
- [ ] Current Production row exposes a Production control and reports Production/Keep/Sell-above distinctly.
- [ ] REFERENCE.md §3.6/§3.10 rewritten; tests cover craft target, reserve, floor and ordering rule; all tests pass. Report on-device checks.
