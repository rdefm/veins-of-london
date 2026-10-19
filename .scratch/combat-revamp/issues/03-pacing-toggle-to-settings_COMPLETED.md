# 03 — Pacing toggle → Settings app

**What to build:** The combat normal/quick pacing toggle moves out of the combat screen into the Phone tab's Settings app, beside the existing preferences. Same persisted value; combat reads it as before.

**Blocked by:** None — can start immediately

**Relevant files:**
- `scenes/phone_apps/settings_app.gd`
- `systems/combat_pacing.gd`
- `scenes/components/combat_director.gd` (toggle_pacing, pacing_label)
- `scenes/screens/combat_rounds.gd`
- `tests/test_combat_director.gd`
- `CODEMAP.md` (settings_app row, combat_director row)

**Status:** ready-for-agent

- [ ] Settings app shows a pacing control (normal/quick) that persists across save/load
- [ ] Combat screen no longer shows a pacing toggle
- [ ] Changing pacing in Settings changes combat playback pause on the next fight
- [ ] CODEMAP rows updated
