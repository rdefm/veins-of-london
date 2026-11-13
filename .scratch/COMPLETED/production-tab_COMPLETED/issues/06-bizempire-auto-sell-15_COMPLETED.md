# 06 — BizEmpire quest: Archie auto-sells 15 items

**What to build:** Change objective `biz_a1_first_order` from "Deliver a full week of James's Time Pearl order" to having Archie auto-sell 15 items. Counts units auto-sold (any item, on-market and off-market) from the moment the objective activates (`bizA1ProductionSeen`); sales before activation never count. Completing it still sets `bizA1FirstOrderDone`, so Beat 7 is unchanged. The recurring Time Pearl order keeps being issued; Beat 6/7 scenes are not touched. The ToDo shows "n of 15" with detail text pointing the player to BizBrief Production (set a Sell-above), and BizBrief's Brief shows a row that deep-links to Production while the objective is active. The target 15 lives in data, not code.

New prose (objective title/detail, Brief row): draft against `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md`, flag `PROSE-REVIEW:` in the report.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/objectives.json` (`biz_a1_first_order`); `systems/objectives.gd` (new type alongside `template_periods_completed`; baselines via `initial_progress()`, `measure()` for ToDo progress); `systems/auto_sell.gd` (`daily_pass`: lifetime auto-sold counter); `autoload/GameState.gd` / `autoload/SaveManager.gd` (counter default + backfill); `systems/business_quest.gd`; `systems/daily_brief.gd`, `data/daily_brief.json`; `data/todo.json`; `systems/phone_nav.gd` (Production deep link); `scenes/phone_apps/bizbrief_app.gd`; `tests/test_objectives.gd`, `tests/test_business_quest.gd`, `tests/test_auto_sell.gd`; `docs/REFERENCE.md` §3.10 "Business Empire questline (Beats 1–8)", §3.6 "Auto-sell"; `docs/writing-guide.md`; `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] New objective type counts on- + off-market auto-sold units since activation; 15 from data; completion sets `bizA1FirstOrderDone`.
- [ ] Auto-sales before activation don't count; old saves mid-quest get a sane baseline (count from load).
- [ ] ToDo shows "n of 15" + detail; Brief row deep-links to BizBrief Production while active.
- [ ] Recurring Time Pearl order and Beat 6/7 scenes unchanged.
- [ ] REFERENCE.md updated; tests cover counting, baseline, completion; all tests pass. PROSE-REVIEW flagged.
