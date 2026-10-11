# 01 — Tracer: DailyBrief projection + Today card with existing attention sources

**What to build:** A thin end-to-end Today card. A new pure DailyBrief system projects the day's plan from game state. Its first sources are the ones "Needs your attention" already knows (raid alarms home/vein, guard wage shortfall) plus pending wage prompts / owed staff wages, all as Urgent rows. The Today card sits first on BizBrief's Brief tab: today's date and time blocks left (same helper as the phone clock), one row per item with label, consequence and one action button routed by existing navigation. The accounts hero, Treasury and Operations sections move below, collapsed by default (session-only). The card refreshes live on state change. The old attention projection is folded into DailyBrief and retired: unread-message rows are dropped (Messages badge covers them); development-eligible veins temporarily appear as plain Routine rows until ticket 07. The Phone home BizBrief badge reads `badge_count()` (Urgent + Story). Row cap and templates start life in a new data table. Works before the business pot opens.

Row shape (from spec, decision-rich):

```jsonc
{ "key": "vein_collapse:<veinId>", "tier": "urgent|story|opportunity|routine",
  "kind": "alarm|bill|arrears|wages|guardShortfall|veinAtRisk|contractAtRisk|objective|offerExpiring|demandSpike|favour|routineSummary",
  "label": "...", "consequence": "...", "action": { "to": "map_vein", "veinId": "v3" },
  "actionLabel": "...", "done": false, "sort": 0 }
```

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/morning_accounts.gd` (`attention_items`, `attention_label`, `open_attention`, wage labels ~L106-174, `open_after_transition`), `scenes/phone_apps/bizbrief_app.gd` (~L288 attention, ~L1127 row build), `scenes/screens/phone.gd` (~L120 badge), `systems/phone_apps.gd` (`build_tile_configs`), `systems/phone_nav.gd` (`open_app`, `open_short_pay`, `select_conversation`), `systems/raid_alarms.gd`, `systems/guard_upkeep.gd` (`pending_shortfall`), `systems/business.gd` (owed wages), `systems/vein_list.gd` (manage option), `scenes/components/phone_device_shell.gd` (`clock_text`, `date_text`), `systems/calendar.gd`, `autoload/GameData.gd` (data load + validation), new `systems/daily_brief.gd`, new `data/daily_brief.json`, new `tests/test_daily_brief.gd`; existing tests `test_morning_accounts.gd`, `test_guard_upkeep.gd`, `test_phone_bizbrief.gd`, `test_phone_home_grid.gd`, `test_phone_nav.gd`, `test_phone_apps.gd`; `CODEMAP.md`. REFERENCE.md §3.1 "Time, rest, daily tick", §3.8 "Home-raid event chain", §3.10 "Contacts, rooms, jobs" (payday/wages).

**Status:** ready-for-agent

- [ ] `DailyBrief.items()`, `badge_count()`, `summary()` (date label, blocks left, per-tier counts) exist; projection is pure (state deep-equal before/after test)
- [ ] Alarm (home + vein), guard shortfall, wage prompt / owed wages rows appear as Urgent and drop off when resolved
- [ ] Rows ordered by fixed tier order then `sort`
- [ ] Each action is a plain data descriptor; BizBrief maps `action.to` onto existing navigation (alarm, short-pay, staff/wages, vein manage)
- [ ] Today card first on Brief; lower sections start collapsed; card updates live while open; available pre-pot
- [ ] `attention_items` and its callers removed/redirected; message rows gone; development rows shown as Routine
- [ ] Phone BizBrief badge = Urgent + Story count
- [ ] `data/daily_brief.json` holds row cap, templates, action labels; templates flagged `PROSE-REVIEW:`
- [ ] CODEMAP rows for new system + data table; check_all + tests green
