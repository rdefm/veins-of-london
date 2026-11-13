# 04 — BizBrief Production master controller

**What to build:** Per the direction approved in ticket 01, the top of BizBrief's Production page gets one master controller for Production target, Keep, Sell-above, sales mood and Cover contracts. Changing it updates every recipe that follows the master immediately; overridden recipes are untouched. Shows a live summary of the effect (e.g. what auto-sell would do today across following recipes). Respects existing gates: page needs Production settings open (Improved Lab / Production-capable contact); Sell-above and mood locked while Sales is unstaffed, Keep and Production aren't. Replaces the "Cover contract needs: all" button.

**Blocked by:** 01 — Production tab design prototype (human-approved direction); 02 — Master + override settings model; 03 — Production target split from Keep.

**Relevant files:** `.scratch/production-tab/spec.md` + `.scratch/production-tab/production-prototype.html` (approved direction); `scenes/phone_apps/bizbrief_app.gd` (`_build_production`, `_build_mood_row`, `_auto_sell_text`); `scenes/ui/stock_bar.gd` (reuse or replace per prototype); `systems/auto_sell.gd` (`projection`); `systems/rooms.gd` (`production_settings_open`); `docs/ui-vision.md`; `tests/test_phone_bizbrief.gd`, `tests/test_stock_bar.gd`; `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Master controller matches the approved prototype direction and edits all five master settings via system calls only (no state writes in the screen).
- [ ] Master edits reach following recipes, not overridden ones; Keep < Sell-above enforced in the control.
- [ ] Locks: page gate and Sales-unstaffed lock behave as today.
- [ ] Headless tests cover master edits, propagation and locks; all tests pass. Report on-device checks (phone width, drag/tap targets, locked states).
