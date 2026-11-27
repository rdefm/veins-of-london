# 02 — Fighters hit by an opening attack still slide in

**What to build:** In the intro fight with Nick, Archie slides in from the player's side together with the player, and only then does Nick attack. Today the player and Nick slide in, and Archie only appears, already in place, once Nick's attack plays. The fix applies to any fight where the enemy acts first: the intro shows the line-up as it stood before the opening attack.

Likely cause (from reading the code, not yet verified by running it): the intro plays against the already-resolved fight state, where Archie is knocked out and so absent from the stage; the pre-attack view is only held afterwards, when the opening beats play.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`_start_fight`, `_play_intro`, `_play_opening`, `_play_from`, `_hold_view`, `_roster_view`)
- `scenes/components/combat_stage.gd` (`sync`, `_player_display_entries`, `prepare_intro`, `start_intro`, `finish_intro`)
- `systems/combat_rounds.gd` (`opening_beats`)
- `data/events/prologue_cold_open.json` (the Nick fight script: `enemyFirst`, forced KO on Archie)
- `tests/test_scripted_fight.gd`, `tests/test_combat_rounds.gd`
- REFERENCE.md §3.7b (Scripted fights); `docs/combat-animation-vision.md` §4.1

**Status:** ready-for-agent

- [ ] Nick fight: Archie slides in with the player, standing, before any attack beat
- [ ] Any enemy-first fight shows its pre-attack line-up, health and status marks during the intro
- [ ] Tapping to skip the intro, quick pacing and reduced motion all end in the correct state
- [ ] Fights without an opening attack look and behave as today
- [ ] No fight outcome or state changes: presentation only
- [ ] Test covers a fighter knocked out by the opening attack being present during the intro
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists on-device checks (Nick fight intro, skipped intro, a normal fight)
