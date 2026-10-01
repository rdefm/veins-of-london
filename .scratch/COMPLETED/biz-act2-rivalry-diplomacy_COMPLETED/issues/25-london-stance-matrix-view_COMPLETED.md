# 25 — London stance matrix view

**What to build:** The Factions app gets a view of London's politics: a stance matrix across every faction pair plus the player, with current wars and truces marked. Big faction-vs-faction stance changes also make the Ticker.

**Blocked by:** 03 — Pressure + relation drift.

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `systems/faction_ai.gd` (read helpers), `systems/barometer.gd`, `docs/ui-vision.md`, `tests/test_phone_factions.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` story 6, §Screens.

**Status:** ready-for-agent

- [ ] The matrix view renders every pair's stance from state. It's read-only, and war/truce markers show when those records exist.
- [ ] A faction-pair stance flip to Hostile or Partner makes a Ticker headline.
- [ ] A phone-app test covers the view building. CODEMAP updated. On-device QA block in the report.
