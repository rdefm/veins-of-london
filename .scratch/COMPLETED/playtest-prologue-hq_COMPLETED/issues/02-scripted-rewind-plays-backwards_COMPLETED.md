# 02 — Scripted Rewind plays backwards fast

**What to build:** When the player Rewinds in the prologue fight, the undone beats play back in reverse at speed instead of the stage snapping straight to the restored state. That includes Archie getting back up from the KO. Ordinary fights already play Rewind in reverse, so find out why the scripted/post-Rewind path skips it and make it use the same playback, quickened.

**Blocked by:** 01 — Cold open: Archie on stage, KO shown.

**Relevant files:** `scenes/screens/combat_rounds.gd` (`_on_rewind_pressed`, `begin_rewind_playback`, `rewind_beats`, `_on_rewind_beat_played`, `_play_cue` rewinding), `scenes/components/combat_director.gd` (pacing), `systems/combat_rounds.gd` (`SCRIPT_POST`/post-Rewind handling, Rewind frames), combat_visuals pacing data; REFERENCE.md §3.7b Rewind.

**Status:** ready-for-agent

- [ ] Prologue Rewind plays the undone beats in reverse order on stage and in the transcript before the post-Rewind plan starts
- [ ] Archie's KO plays in reverse (he gets back up)
- [ ] Reverse playback runs faster than forward pacing; the speed is a data value, not a code constant
- [ ] Normal-fight Rewind behaviour unchanged (existing tests pass)
- [ ] Headless test: the scripted Rewind path produces a non-empty reversed beat list that includes Archie's KO
