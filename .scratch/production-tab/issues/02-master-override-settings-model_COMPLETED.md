# 02 — Master + override production settings model

**What to build:** Replace per-recipe Production/auto-sell settings with one master setting set plus optional per-recipe overrides. A setting set is `{production, keep, sellAbove, mood, coverContracts}`. A recipe with no override follows the master live; editing any field on a recipe copies the full master into an override for that recipe and applies the edit (from then on every field of that row is manual); reverting deletes the override. All readers of targets, cover flags and auto-sell rules (staff crafting, auto-sell, contract reserve, morning accounts, load clamp, debug start) go through one resolver. Master defaults: Production 0, Keep 0, Sell-above 50 (`productionTargetMax`, sells nothing), mood Balanced (`defaultMood`), Cover contracts on. Save migration resets every save to master defaults (drops old per-recipe targets, cover flags and auto-sell rules). Craft behaviour is otherwise unchanged in this ticket: Keep is still the craft target (ticket 03 splits it). The current Production UI keeps working: its existing setters now create/edit overrides.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/rooms.gd` (`set_lab_threshold`, `set_lab_cover_contracts`, `lab_covers_contracts`, `lab_covers_all_contracts`, `toggle_all_lab_cover_contracts`, `effective_lab_target`, `clamp_lab_thresholds`, producer step); `systems/auto_sell.gd` (`rule`, `_store_rule`, `set_keep`, `set_sell_above`, `set_mood`, `protected_floor`); `systems/morning_accounts.gd`; `systems/contracts.gd` (`_shared_stock`, `_producer_cost`); `autoload/GameState.gd` (`labThresholds`, `labCoverContracts`, `autoSell` defaults); `autoload/SaveManager.gd` (SAVE_VERSION 14 → 15, load fix-ups/clamps); `autoload/GameData.gd` (`PRODUCTION_TARGET_MAX`); `systems/debug_start.gd`; `data/constants.json`; `data/market.json` `autoSell`; `tests/test_rooms.gd`, `tests/test_auto_sell.gd`, `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §2 state tree (labThresholds/autoSell lines), §3.6 "Auto-sell", §3.10 Producer; `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] State holds a master setting set and an overrides map; pure data, saved/loaded, defaults as above.
- [ ] Resolver returns the effective setting set per recipe (override if present, else master); every former reader of `labThresholds` / `labCoverContracts` / `autoSell` uses it.
- [ ] Setting any field on a recipe creates a full override (master copy + edit); revert removes it; master edits change all non-overridden recipes only.
- [ ] Migration to save v15 resets to master defaults; old fields removed or ignored; old saves load clean.
- [ ] No behaviour change beyond defaults/migration: existing crafting, auto-sell and contract tests pass (updated only for the new state shape).
- [ ] REFERENCE.md §2/§3.6/§3.10 and CODEMAP updated; tests for override/revert/master propagation/migration; all tests pass.
