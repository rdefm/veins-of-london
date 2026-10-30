# 09 — Enhancement Powder + Be a Lady

**What to build:** The two self-buffs show while they run (proposal §3.6, §3.8):

- **Powder launch:** `cast` with a small green-gold dust puff at head height; one afterimage peels off at once.
- **Powder linger** (while `powderUntil` holds): idle at ~1.6× speed; every lunge/throw leaves a faint 2-ghost afterimage trail (idle stays clean). The bonus action's strip card carries a green "+1" corner tab.
- **Powder exit:** idle eases back over ~300ms with a tiny puff.
- **Lady launch:** `cast`; a brass glint sweeps up the sprite (~250ms).
- **Lady linger** (while `ladyUntil` holds): each Strike that lands gets a 1-frame clover-green glint at impact, and its damage number is brass (always a max roll). A crit under Lady gets a slightly bigger glint and ~40ms extra hit-stop.
- Carry-in Lady (active at fight start) shows the linger from round 1 with no launch.

**Blocked by:** 01 — Status icon row

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()` powder/lady in `_CAST_KINDS`, damage cue)
- `scenes/components/combat_stage.gd` (`spawn_afterimage()`, idle fps, `spawn_damage_number()`)
- `scenes/components/turn_order_strip.gd` (+1 tab)
- `systems/combat_rounds.gd` (`has_lady()`, extra-action marking for the strip entry)
- `data/combat_visuals.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7b Items (enhancementPowder, beALady), Carry-in effects

**Status:** ready-for-agent

- [ ] Powder puff, faster idle, movement trails, +1 strip tab, eased exit
- [ ] Lady glint, impact glints, brass numbers, bigger crit glint
- [ ] Carry-in Lady shows from round 1
- [ ] Rewind restore sets lingers directly; KO clears instantly; quick pacing halves; reduced motion drops trails and glints, keeps brass numbers and +1 tab
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: a Powder round with its extra action; Lady strikes and a Lady crit
