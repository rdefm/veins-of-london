# 05 — Skip button while KO'd

**What to build:** When the player is KO'd and at least one ally is still standing, a Skip button appears in the combat screen. Tapping it resolves the rest of the fight instantly, with no beat animation, and goes straight to the normal outcome flow (win/loss, after-effects, player HP set per Player KO). Resolution uses exactly the same rules and RNG path as watching the fight play out. Skip is a shortcut, not a different simulation.

The system-side resolve runs round by round until the outcome, with a hard iteration cap. If the cap is ever hit, it must resolve deterministically and not hang. Raise the cap behaviour with the human if it's needed. The screen only calls the system function; it never mutates state.

New mechanic: draft the REFERENCE.md wording for Skip under §3.7b "KO and outcome" / §3.7a "Player KO", and get the human's approval before marking it complete.

**Blocked by:** 02 — Action cards vanish after player KO.

**Relevant files:**
- `systems/combat_rounds.gd` (round loop ~1855, `_check_outcome()` ~2606, `playerKoed`)
- `scenes/screens/combat_rounds.gd` (KO state, round playback)
- `scenes/components/combat_command_dock.gd` (button placement)
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.7a "Player KO", §3.7b "KO and outcome"
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Skip is visible only when the player is KO'd, an ally is standing and no outcome is set yet
- [ ] Skip produces the same outcome and state as playing the remaining rounds out for the same seed (test)
- [ ] The resolve loop has an iteration cap; a test proves it terminates
- [ ] Outcome flow after Skip is identical to the normal end of the fight
- [ ] REFERENCE.md wording drafted and human-approved; CODEMAP updated
- [ ] On-device check listed in the report
