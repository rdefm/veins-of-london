# 08 — Time Pearl freeze: tape-stop in, play-snap out, edge cases

**What to build:** The freeze reads during beat playback instead of popping on/off:

- **Tape-stop in (~150ms):** on the Time Pearl beat, each affected sprite does a brief downward smear/drag then holds, then the VCR-pause loop (06) and ⏸ icon (07) start.
- **Play-snap out (~150ms):** when a fighter's last frozen action passes, one tracking band sweeps up, the sprite jolts, the icon clears and normal idle animation resumes.
- **KO while frozen:** effect and icon clear instantly, no play-snap.
- **Rewind:** during Rewind playback the full-screen VHS overlay draws over everything, with frozen sprites keeping their pause shader underneath. A restored frame rebuilds the freeze state directly — no tape-stop or play-snap.
- Hold-to-peek and tap-target on a frozen fighter keep working.
- Durations in `combat_visuals.json` `freezeFx`; quick pacing halves them.

**Blocked by:** 06 — VCR-pause shader; 07 — pause icon with count + strip cards marked

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (beat playback, Rewind playing undone beats in reverse, restored opening)
- `scenes/components/combat_stage.gd` (`set_slot_frozen()`, `set_rewind_effect()`, slot taps/holds)
- `scenes/components/combat_director.gd` (beat pacing, quick mode)
- `data/combat_visuals.json` (`freezeFx`)
- `CODEMAP.md` rows for touched files

**Status:** ready-for-agent

- [ ] Tape-stop plays on the Time Pearl beat before the pause loop starts
- [ ] Play-snap plays when the last frozen action passes; idle resumes
- [ ] KO clears freeze visuals instantly
- [ ] Rewind: pause look under the VHS overlay; restored frames show correct freeze state with no transitions
- [ ] Peek/tap on frozen fighters unaffected
- [ ] Durations data-driven; quick pacing halves
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: tape-stop/play-snap land on the right beats, KO and Rewind cases
