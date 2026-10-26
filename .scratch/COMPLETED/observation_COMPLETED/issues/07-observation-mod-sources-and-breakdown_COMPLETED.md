# 07 — Observation mod sources + breakdown

**Phase:** MVP

**What to build:** The player's kit shapes their reads, and they can see why. Add mod sources: seated Movement attunement (matching ore, flat, scaled by Movement tier), Be A Lady (`ladyBonusPerLevel × level`, all ores), Prophet's Breath active (time, flat), and the item `observeBonus: {ore|"all": delta}` data hook. Each mod is labelled. Tapping a roll line in the sheet shows the mod breakdown (which bonuses lowered the number needed). All numbers in data, placeholders.

**Blocked by:** 05.

**Relevant files:** `systems/observation.gd`, `systems/dial.gd` (seated Movement / attunement), `systems/active_effects.gd` (Lady, Breath), `data/constants.json` (`ladyBonusPerLevel` ~l.678, new observation keys), `data/combat_rounds.json` (prophetsBreath), `scenes/screens/event.gd`, `tests/test_observation.gd`, `tests/test_event_screen.gd`; REFERENCE.md Observation §.

**Status:** ready-for-agent

- [ ] Attunement applies only to the matching ore, scaled by Movement tier
- [ ] Lady applies to all ores per level; Breath to time only while active
- [ ] `observeBonus` on an item entry applies per ore or "all"
- [ ] Each mod appears labelled in the display row breakdown
- [ ] Tap roll line shows breakdown in sheet
- [ ] Numbers in data, flagged placeholder
