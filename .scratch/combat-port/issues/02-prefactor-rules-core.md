# 02 — Prefactor: prototype rules core runs on any combat dict

**What to build:** Make the change easy. The prototype's resolution (plan rolling, timeline ordering, the resumable cursor, guard-state rules, fog, beats, per-action decisions, rewind snapshots) currently assumes it owns `state.combatPrototype`. Refactor it so the core takes the combat dict (and its RNG streams) it works on, so live `Combat` can drive the same rules on `state.combat`. The sandbox stays a thin caller of that core. No behaviour change: the prototype screen, its tests and its sim behave identically.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat_prototype.gd`; `scenes/screens/combat_prototype.gd`; `tests/test_combat_prototype.gd`; `tests/test_combat_prototype_screen.gd`; `scripts/sim_combat_prototype.gd`; `scripts/sim_combat_prototype_impl.gd`; `CODEMAP.md`

**Status:** ready-for-agent

- [ ] The rules core resolves a fight held in any passed-in pure-data combat dict
- [ ] The prototype tests pass unchanged; the screen test passes
- [ ] The prototype sim's seeded output is identical before and after
- [ ] CODEMAP row updated
