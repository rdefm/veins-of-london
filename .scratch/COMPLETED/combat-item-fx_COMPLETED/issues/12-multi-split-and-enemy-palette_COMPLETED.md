# 12 — Multi-target split + enemy item palette

**What to build:** Two cross-item tells (proposal §3.17, §3.18):

- **Multi-target units:** one launch; the travel projectile **splits** mid-flight into one path per target; land effects play staggered ~60ms in combatant order; one shared shake. Applies to every item that can be multi (Blast, Shield, Healing Burst, Pan items).
- **Enemy items** (raider kit / enemy capabilities): the same effects with the palette shifted ~20% toward grey-steel, so an enemy's Shield/Blast/heal is clearly theirs. Enemy Shield's shimmer uses the shifted palette too.

**Blocked by:** 03 — Effect plumbing + Blast; 04 — Shield; 05 — Healing Burst

**Relevant files:**
- `scenes/screens/combat_rounds.gd` (`beat_cues()`, the beat's `multi`/`affected` fields)
- `scenes/components/combat_stage.gd` (travel cue, `play_effect()`, shield loop)
- `systems/combat_rounds.gd` (which beats carry multi targets; actor side)
- `systems/loadout.gd` (`multi` flag)
- `data/combat_visuals.json` (shift amount)
- `tests/test_combat_rounds.gd`, `tests/test_combat_stage.gd`
- REFERENCE.md §3.7 Loadout (multi-target units), §3.7b Table 5 (enemy kit)

**Status:** ready-for-agent

- [ ] Multi units split the projectile; staggered lands; single shake
- [ ] Enemy-used items render in the shifted palette, including enemy Shield shimmer
- [ ] Quick pacing halves the stagger; Rewind clean
- [ ] Syntax check clean; full suite passes; CODEMAP updated
- [ ] Human on-device check: a multi Blast and a multi heal; a raider Shield and Blast
