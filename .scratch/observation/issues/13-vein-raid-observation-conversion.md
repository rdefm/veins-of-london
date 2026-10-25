# 13 — `vein_raid` becomes an observation raid (placeholder prose)

**Phase:** MVP

**What to build:** `vein_raid` plays end-to-end as an observation raid. Approach beat: tension card + raid observation (aim for all 5 ores, tiers + miss). Route beat: always-on "Just go in" (low-base check with raid factor mods, runKey-seeded) and "Go in loud" (straight to fight); read-unlocked quiet routes (one per ore where it fits), each a check with a good base plus `observed atLeast: 2` mods; some routes incapacitate guards. A failed route → `start_raid_combat` with `situational` mods from reads. Caught beat: fight intro lines. Claim / Loot unchanged. Old Go slow / Go fast and their `stealth_check` removed from `vein_raid` only. Placeholder prose OK; prose tickets 14–16 replace it.

**Blocked by:** 08, 10, 11, 12.

**Relevant files:** `data/events/vein_raid.json`, `systems/raiding.gd`, `tests/test_raiding.gd`, `tests/test_raid_alarms.gd`, `tests/test_event_content_lint.gd`; REFERENCE.md raiding §.

**Status:** ready-for-agent

- [ ] Playthrough test: observe → unlocked route → success → claim/loot
- [ ] Playthrough test: route fails → combat with expected situational mods
- [ ] Incapacitate route reduces guards; all down skips fight
- [ ] "Just go in" and "Go in loud" always available
- [ ] Observing never triggers detection
- [ ] Go slow / Go fast gone from `vein_raid`; stockpile raids untouched
- [ ] Lint clean; all numbers placeholders in data
