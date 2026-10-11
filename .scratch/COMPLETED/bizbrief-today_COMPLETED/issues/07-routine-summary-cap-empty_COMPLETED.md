# 07 — Routine summary row, row cap, empty state

**What to build:** All Routine items (development-eligible veins, non-urgent at-risk veins, idle staff, production short of ore) collapse into one Routine summary line that expands on tap to individual rows. The visible card caps at the data row cap (default 6) with "+N more" to expand; the Routine summary never takes more than one row. When nothing is pressing the card shows a short in-voice empty-state line from data.

Note: the spec's Routine bullet says "veins ready to prune"; the existing source is development eligibility. If those differ, ask before inventing a prune-ready rule.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card; 03 — Vein-at-risk row.

**Relevant files:** `systems/cultivating.gd` (`is_development_eligible`), `systems/rooms.gd` (staff output, ore needs), `systems/hiring.gd`, `systems/time_system.gd` (`run_staff_block`), `systems/daily_brief.gd`, `data/daily_brief.json`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_daily_brief.gd`, `tests/test_phone_bizbrief.gd`. REFERENCE.md §3.4 "Cultivating & pruning", §3.10 "Contacts, rooms, jobs".

**Status:** ready-for-agent

- [ ] Single `routineSummary` row aggregates counts; expands to individual rows
- [ ] Cap + "+N more" from data; Routine summary ≤ 1 row (test)
- [ ] Idle staff and ore-short production sources tested
- [ ] Empty state shown when no rows; line in data, `PROSE-REVIEW:` flagged
