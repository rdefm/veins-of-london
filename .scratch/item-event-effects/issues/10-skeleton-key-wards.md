# 10 — Skeleton Key (raid ward triggers)

**What to build:** During a raid, Skeleton Key cancels up to N ward triggers, using the wards' existing `counters` slot (brainstorm §4). Its event bypass is ticket 22.

**Blocked by:** 01

**Relevant files:** `systems/raiding.gd`, `systems/raid_alarms.gd`, `data/wards.json`, `tests/test_raiding.gd`; REFERENCE §3.12.

**Status:** ready-for-agent

- [ ] N triggers are cancelled, then wards behave normally
- [ ] Spent on use; tier scales N
