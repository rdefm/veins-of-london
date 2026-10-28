# 03 — Hand-off: Prep sheet and top board exit upward

**What to build:** Tapping Fight on the Preparation sheet starts the combat intro with a hand-off: the Prep sheet slides **up** off-screen and the top departure board (notification "travel" board) goes up with it as one piece, revealing the combat stage underneath. No dip to black or flat colour. The intro (ticket 01) then continues from "stage up".

- Applies to every combat entry that passes through Prep (planned and forced).
- Duration in `combat_visuals.json` `intro`; quick pacing halves it; tap-skip skips it.
- The top board stays hidden for the fight as now, and returns as normal on exit.

**Blocked by:** 01 — Combat intro: stage, fighters, HUD reveal

**Relevant files:**
- `scenes/screens/combat_prep.gd` (Prep sheet, Fight footer)
- `scenes/components/top_bar.gd` (departure board; hidden on combat)
- `scenes/Main.gd` (screen swap, top-board/nav-dock visibility per screen)
- `systems/combat_prep.gd` (commit on Fight) — read only
- `scenes/screens/combat_rounds.gd` (intro start)
- `data/combat_visuals.json` (`intro` key)
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Fight slides Prep sheet + top board up together; stage revealed underneath, no black/flat dip
- [ ] Works for planned and forced fights
- [ ] Quick pacing halves, tap skips
- [ ] Top board reappears normally after combat exits
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: board and sheet move as one, no flicker/gap, return after fight
