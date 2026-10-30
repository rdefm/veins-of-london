# 02 — Run-off exit for Leg it and Panic bolt

**What to build:** A fighter who successfully Legs it, or who bolts on a Panic turn, visibly runs off stage instead of folding out like a Wormhole. The fighter flips to face away (mirror), takes a 1-frame crouch, then slides off the nearest screen edge fast (~300ms, ease-in), leaving 2 afterimages and a small dust kick where it started. Rewind plays it backward: the fighter runs back in. Wormhole keeps the existing fold-to-a-line vanish, so running away and folding out of space never look alike.

Design: `.scratch/combat-item-fx/proposal.md` §3.9 (run-off exit), §3.13.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()`, where `fled`/`bolt` currently map to `vanish`; `_play_cue()` rewinding branch)
- `scenes/components/combat_stage.gd` (`play_wormhole_vanish()`, `restore_from_vanish()`, `spawn_afterimage()`, slot side/mirror)
- `data/combat_visuals.json` (durations)
- `tests/test_combat_rounds.gd` (`beat_cues` mapping), `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Moves (legIt), Table 4 (panic bolt)

**Status:** ready-for-agent

- [ ] `fled` and `bolt` beats play the run-off; `wormhole` still plays the fold vanish
- [ ] Exits by the nearest edge for both bands and every fan slot
- [ ] Rewind runs the fighter back in to its slot
- [ ] Durations data-driven; quick pacing halves; reduced motion drops the dust kick and afterimages
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: Leg it success, Panic bolt and Wormhole each read differently; Rewind past each
