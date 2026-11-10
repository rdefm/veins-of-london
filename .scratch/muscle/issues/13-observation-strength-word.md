# 13 — Observation strength word

**What to build:** Observing a faction site shows guard count plus a strength word from the average weight per guard: green (<1.25), hardened (<1.75), seasoned (≥1.75). The site's security signature includes level counts, so a site reads as changed when its guards level up or are swapped. Faction Reserve size stays hidden.

**Blocked by:** 11 — Faction muscle counts.

**Relevant files:**
- `systems/muscle.gd` (`strength_word`), `systems/observation.gd` (`security_signature`, observe read), `systems/intel.gd`
- `data/constants.json` (`muscle` strength cut-offs)
- Tests: `tests/test_observation.gd`, `tests/test_security_profile.gd`, `tests/test_muscle.gd`

**Status:** ready-for-agent

- [ ] Strength word cut-offs correct at 1.25 and 1.75
- [ ] Changing a site's level mix (same count) changes its signature → site reads as changed
- [ ] Reserve size never appears in observation
- [ ] PROSE-REVIEW flagged: observation strings
