# 20 — Check tags + `entry` → `tags` migration

**What to build:** Checks (and no-roll options) carry `tags` from a fixed vocabulary in constants: `physical`, `social`, `discovery`, `barrier`. Every `entry: "physical"` check is migrated to `tags: ["physical"]`. Enhancement Powder's lasting bonus now applies to later checks that share its tag, so raids behave exactly as before. See spec "Check tags".

**Blocked by:** 01

**Relevant files:** `.scratch/item-event-effects/spec.md`, `systems/events.gd`, `systems/event_items.gd`, `data/constants.json`, `data/events/*.json` (61 `entry` checks, incl. `raid_*.json`, `vein_raid.json`), `tests/test_event_items.gd`, `tests/test_events.gd`; REFERENCE §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] No `entry` field remains in live data; all migrated checks carry `tags`
- [ ] Powder's lasting bonus applies to later same-tag checks; existing raid tests pass unchanged
- [ ] REFERENCE §3.9a documents tags and the migration
