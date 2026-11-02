# 22 — No-roll bypasses (Blast, Skeleton Key) + Blast content migration

**What to build:** Blast and Skeleton Key options are authored no-roll options gated by `requires` on the item. On commit they always succeed. The resolver spends the item and applies its profile's built-in alert change (Blast +1 tier, clamped; Skeleton Key none) before the option's own effects. Every existing Blast check option is converted: success text → `result_text`, success effects/goto → the option's, fail branch dropped, duplicate authored alert raises removed. Profiles for Signal Failure, Pan's Rapture and Pandemonium (untagged `unlock`) are added. See spec "No-roll bypasses".

**Blocked by:** 21

**Relevant files:** `systems/events.gd`, `systems/event_items.gd`, `data/recipes.json`, `data/events/raid_arches.json`, `data/events/raid_playground.json`, `data/events/raid_shop.json`, `data/events/vein_raid.json`, `tests/test_event_items.gd`, `tests/test_events.gd`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Blast: no roll, always succeeds, alert +1 (clamped), raise applied before the option's effects, item spent
- [ ] Skeleton Key: no roll, always succeeds, alert unchanged
- [ ] All live Blast options converted; each converted option listed PROSE-REVIEW in the report
- [ ] REFERENCE §3.9a documents the bypass alert ordering
