# 04 — Combat layout: board hidden + transcript

**What to build:** In combat the whole top departure board disappears to free space. The combat screen is, top to bottom: stage and sprites; a smallish **transcript** — a play-by-play of each resolved action and its result, one line each, newest always visible, older lines scroll up; then the command area. Combat lines no longer go to the notification ticker. Board returns when the fight ends.

**Blocked by:** None — can start immediately

**Relevant files:**
- `scenes/components/top_bar.gd` (combat hold / combat-line feed)
- `scenes/components/notification_ticker.gd` (transient combat-log entries)
- `scenes/Main.gd` (board mounting)
- `scenes/screens/combat_rounds.gd`, `scenes/screens/combat.gd`
- `scenes/components/combat_director.gd` (beat playback — transcript lines appear in step with beats, incl. Rewind)
- `data/combat_rounds.json` (beat strings)
- New transcript component + `tests/test_<component>.gd`
- `CODEMAP.md`; `docs/ui-vision.md` (styling)

**Status:** ready-for-agent

- [ ] Departure board hidden on entering combat, restored on exit (all exit routes incl. fled/KO)
- [ ] Each resolved action (move, item, Dial cast, evade, KO, status tick) adds one transcript line with its result (e.g. damage)
- [ ] Lines appear in step with beat playback, not ahead of it
- [ ] Rewind removes the undone lines
- [ ] No combat lines reach the ticker/Notifications
- [ ] Human check: on-device layout — stage, transcript, command area, no overlap at phone width
