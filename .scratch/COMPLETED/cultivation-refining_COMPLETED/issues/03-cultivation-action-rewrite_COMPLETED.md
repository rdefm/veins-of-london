# 03 — Cultivation action rewrite: uniform random gain, no success roll

**What to build:** Cultivate always applies a positive whole-number condition gain — no separate success/failure roll, no diminishing-toward-ceiling shrink. The gain is uniformly rolled between a skill-dependent minimum and maximum inclusive, and is applied in full, clamped only by remaining headroom to the ceiling (a ceiling-limited gain can be smaller than the nominal minimum — that's not a failed roll).

Resolved formula (from the cultivation-refining grilling session, sized so skill-1's minimum roll exactly covers the worst-case level-1 nightly drift of `1+5=6` from ticket 01):
`minGain(skill) = skill + 5`, `maxGain(skill) = minGain(skill) + 4`. XP per cultivate action is a flat 15 (replacing the old 20-success/8-fail split; the skill-level XP thresholds table `CULTIVATING_XP_LEVELS` is unchanged).

**Blocked by:** 01 (needs `level`-scaled drift to validate the maintenance guarantee against).

**Relevant files:**
- `systems/cultivating.gd` (`cultivate()`, `cultivate_gain()` — remove `cultChance` roll and the `(1 - growth/ceiling)` taper entirely)
- `data/vein_growth.json` (replace `cultivateBase`/`cultivatePerSkill`/`cultivateMinGain` with the new min/max-by-skill constants)
- `docs/REFERENCE.md` §1.2 (cultivate formula description, once approved)

**Status:** ready-for-agent

- [ ] `cultivate()` no longer rolls a success/fail chance; every call applies a gain
- [ ] Gain is uniformly rolled `[skill+5, skill+9]` inclusive, applied and clamped to the ceiling
- [ ] A ceiling-clamped gain smaller than `skill+5` is not treated as or logged as a failure
- [ ] XP awarded is a flat 15 per action
- [ ] Test: skill 1, repeated minimum rolls (6) on a level-1 vein exactly offset the worst-case drift (6) from ticket 01 — net progress is zero-or-better every day
- [ ] Test: gain range bounds are correct at several skill levels; ceiling clamping behaves as specified
