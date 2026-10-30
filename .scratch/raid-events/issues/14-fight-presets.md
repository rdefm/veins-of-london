# 14 — Fight presets

**What to build:** An event file can define named fight setups (guard source, enemy template, fight-start conditions) once at the top. A raid fight effect can then name the preset and override parts of it: guard count (e.g. only the line guard) and extra fight conditions appended to the preset's (e.g. guards strike first). `vein_raid`'s ten pasted copies of the guard fight become one preset and references, with identical fights on every path.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`_start_raid_combat()` ~L1430), `systems/combat.gd` (`situational_active()` ~L451, `start_raid()`), `data/events/vein_raid.json`, `tests/test_raiding.gd`, `tests/test_event_content_lint.gd`, `tools/storyboard.html` (if it edits fight effects), REFERENCE.md §3.7b Open/Guarded round combat.

**Status:** ready-for-agent

- [ ] Preset schema and override rules documented in R§3.7b
- [ ] `vein_raid` uses one preset; no fight setup is duplicated in it
- [ ] Tests: preset-only fight equals the inline equivalent; guard-count override; appended fight conditions; unknown preset name fails lint
- [ ] Existing raid tests pass unchanged
