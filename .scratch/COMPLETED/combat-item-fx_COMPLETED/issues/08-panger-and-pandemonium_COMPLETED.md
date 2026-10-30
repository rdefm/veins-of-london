# 08 — Panger + Pandemonium

**What to build:** Anger's two phases and Pandemonium's fury are visible on the sprite (proposal §3.11, §3.12):

- **Launch:** `throw` with a red spark (ticket 03 travel cue). **Land:** the sprite flashes deep red twice (modulate, not the white hit flash).
- **Hot phase** (deals +X%, takes −X%): a red rim pulse (~1Hz), sprite scale +4%.
- **Cold phase** (deals −X%, takes +X%): a bruise-purple rim, scale −4%, a 1-px slump.
- **Phase flip:** the rim colour flips with a 1-frame squash, because it flips who should be hitting whom.
- **`calm` beat:** the rim fades out over ~300ms and scale eases home.
- **Pandemonium fury:** adds a small looping steam wisp above the head while furious. Before a friendly-fire Strike, a magenta line flashes 2 frames from attacker to its ally target so the eye follows the wrong-way attack.

**Blocked by:** 01 — Status icon row; 03 — Effect plumbing + Blast

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` anger/fury/calm; `_OVERLAY_KINDS`)
- `scenes/components/combat_stage.gd`
- `systems/combat_rounds.gd` (`anger_factor()`, `_tick_anger()`, `stage_marks()`)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Table 4 (panger, pandemonium), Damage (anger factors)

**Status:** ready-for-agent

- [ ] Red double flash on land
- [ ] Hot and cold rims and scales track the phase; visible flip
- [ ] Calm fade
- [ ] Fury steam wisp; friendly-fire flash line before the swing
- [ ] Rewind restore sets phase directly; KO clears instantly; quick pacing halves; reduced motion drops the pulse and scale, keeps the rim colour
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: Panger through both phases to calm; Pandemonium friendly fire
