# 02 — Security header and summary strip

**What to build:** the Security screen's top section on every tab. One header row: "‹ HQ" back on the left, "Security" title, "Hire ›" on the right (opens the hire board; disabled without the Security Office). Under it a one-line summary strip: guards · posted · ready · out · Mon bill £N. Tabs restyled as an underlined three-column row (Posts / Guards / Costs). The no-office notice stays.

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (all artboards' header).

**Blocked by:** 01 — Muscle readouts for the Security UI.

**Relevant files:** `scenes/screens/security.gd` (`_build`, `_build_tabs`), `systems/guard_upkeep.gd` (Monday bill), `scenes/components/map_card_style.gd`, `data/palette.json`, `docs/ui-vision.md` (Family 4 field-kit chrome, `ui_action_red`), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Header row with back, title, Hire › on all three tabs
- [ ] Summary strip numbers come from Muscle / GuardUpkeep readouts and update on state change
- [ ] Underlined tab row; Costs deep link (`PhoneNav.take_security_tab`) still lands on Costs
- [ ] Any new colours live in `data/palette.json`, none in code
- [ ] check_all clean; full suite green
- [ ] PROSE-REVIEW: strip labels
- [ ] On-device checklist in the report
