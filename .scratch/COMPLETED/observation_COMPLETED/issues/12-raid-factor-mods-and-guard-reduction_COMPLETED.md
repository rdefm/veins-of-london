# 12 — Raid factor mods + guard reduction

**Phase:** MVP

**What to build:** Raid observations feel the site. A raid-factor mod source applies labelled mods to every ore: security / raid resist, value, intel on owning faction (`Intel.raid_odds_shift`, incl. disinformation penalty), Network handler `claim_bonus`, grudge bonus, Muscle perk. An event op reduces the raid's guard count (incapacitate routes); zero guards left skips the fight. Stealth and stockpile raids untouched.

**Blocked by:** 07.

**Relevant files:** `systems/raiding.gd`, `systems/intel.gd`, `systems/grudges.gd`, `systems/observation.gd`, `systems/events.gd` (~l.1277 `vein_guard_count`), `tests/test_raiding.gd`, `tests/test_observation.gd`; REFERENCE.md raiding §.

**Status:** ready-for-agent

- [ ] Each raid factor appears as a labelled mod on raid observations only
- [ ] Disinformation lowers reads
- [ ] Guard-reduction op lowers guard count; at zero the fight is skipped
- [ ] `stealth_check` and stockpile raids unchanged
