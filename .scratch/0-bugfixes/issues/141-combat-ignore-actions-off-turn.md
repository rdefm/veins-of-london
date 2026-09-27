# 141 — Combat ignores actions while it's not the player's turn

**What to build:** While a round's beats are playing out (enemy/ally turns), the player's commands — Attack, Run, the dial, and Bag item use — are dimmed and taps on them do nothing. Today the dock and Bag deliberately stay live and a new command skips the running playback to its end, so spamming animates out of order and the turn sequence becomes confusing. Commands become live again once playback finishes and it's the player's turn.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat.gd` (`_play_round`, `_finish_playback` ~L305-318, `_on_attack_pressed`, `_on_run_pressed`, `_on_dial_triggered`), `scenes/components/combat_command_dock.gd` (`_build_action_row` disabled state), `scenes/components/bag_drawer.gd`, `systems/combat.gd`; REFERENCE.md §3.7 "Combat".

**Status:** ready-for-agent

- [ ] Taps on Attack/Run/dial/Bag items during playback are ignored (no state change, no playback skip)
- [ ] Controls render dimmed during playback and re-enable when playback ends
- [ ] Quick and Normal pacing both behave
- [ ] Human on-device: spam Attack during an enemy turn — nothing happens until it's your turn; same for a Bag item
