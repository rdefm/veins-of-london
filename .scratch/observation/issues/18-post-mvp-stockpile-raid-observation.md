# 18 — `stockpile_raid` becomes an observation raid

**Phase:** Post-MVP

**What to build:** Convert `stockpile_raid` from `stealth_check` to the observation raid pattern used by `vein_raid` (read the place, quiet routes unlocked by reads, Just go in / Go in loud, situational fight mods). Placeholder prose OK; prose per beat as separate tickets.

**Blocked by:** MVP playtest sign-off by the human; 13.

**Relevant files:** `data/events/stockpile_raid.json`, `data/events/vein_raid.json` (pattern), `systems/raiding.gd`, `tests/test_raiding.gd`.

**Status:** needs-triage

- [ ] No `stealth_check` left in this event
- [ ] Playthrough test: success and caught paths
- [ ] Lint clean
