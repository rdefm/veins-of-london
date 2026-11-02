# 31 — Blast content migration to the built-in cover

**What to build:** Every Blast option stops authoring its own `alert atLeast 2` raise (with or without cover). Blast's built-in profile alert and cover do the work, so each use is exactly +1 unless covered. Authored cover text moves to the option's `coveredText`. Per-event cover mods either move to the profile default or become an option-level cover override (decide in-ticket; default on the profile).

**Blocked by:** 30

**Relevant files:** `data/events/raid_arches.json`, `data/events/raid_shop.json`, `data/events/vein_raid.json`, `data/recipes.json`, `tests/test_events.gd`, the content-lint test; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] No Blast option carries its own `alert atLeast` effect
- [ ] Authored cover text carried over as `coveredText`
- [ ] Blast is exactly +1 uncovered, unchanged when covered, in each converted event
- [ ] All live event data passes the lint
- [ ] Each converted option listed PROSE-REVIEW in the report
