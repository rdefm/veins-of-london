# 17 — Cover roll on alert

**What to build:** An alert raise can carry a cover roll: before the alert rises, luck gets a chance to hide the noise (a car backfires as the window breaks). On success the alert doesn't rise and the cover line shows in the result text. On failure the alert rises as normal. The cover odds have a base set by the author, plus Be A Lady's bonus and any authored observation or condition modifiers (e.g. a fate observation). Today's fixed-odds `chance` effect can't take Be A Lady's bonus. The roll is seeded like other event rolls, so Rewind is consistent.

**Blocked by:** 16 — Raid alert level.

**Relevant files:** `systems/events.gd` (`chance` op ~L1043, Be A Lady bonus in the check maths ~L537, `_mod_delta()`), `systems/active_effects.gd` (`lady_level()`), `data/constants.json` (`EVENT_CHECKS` Lady bonus), `tests/test_events.gd`, REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Cover schema documented in R§3.9a
- [ ] Tests (seeded): cover success leaves alert unchanged and shows the cover line; failure raises it; Be A Lady raises cover odds; an authored observation modifier applies; no cover field means an unconditional raise
- [ ] Cover result text flagged `PROSE-REVIEW:` if any default line is added
