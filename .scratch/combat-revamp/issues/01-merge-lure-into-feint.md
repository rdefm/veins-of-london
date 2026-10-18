# 01 — Merge Lure into Feint

**What to build:** Lure stops existing as a move. Feint absorbs the "open a turtle" job: a Feint on a target makes that target's **next Guard action fail** (it stays Open through it). The Fight move set becomes Strike / Guard / Feint / Stun (Leg it stays its own command). Exposed — only ever produced by a sprung Lure — goes too, along with its marker, beats and transcript strings. Balance sim re-run; REFERENCE updated to match.

**Blocked by:** None — can start immediately

**Relevant files:**
- `data/combat_rounds.json` (moves.lure, archetype patterns, beat strings `lure`/`exposed`)
- `systems/combat_rounds.gd` (EFFECT_LURE, LURE_* state, `exposedUntil`, `is_exposed`, EXPOSED guard marker, ally AI feint logic)
- `systems/combat.gd`
- `scenes/screens/combat_rounds.gd`, `scenes/components/combat_stage.gd` (Exposed marker)
- `autoload/GameData.gd` (move validation), `autoload/SaveManager.gd` (in-flight combat dict with lure fields)
- `tests/test_combat_rounds.gd`, `tests/test_combat.gd`, `tests/test_combat_command_dock.gd`, `tests/test_gamedata.gd`
- `scripts/sim_combat_balance.gd` (+ `_impl.gd`)
- REFERENCE §3.7b Open/Guarded round combat — Moves, Damage, Evade, Removal

**Status:** ready-for-agent

- [ ] No `lure` move, effect, state field, pattern entry or string remains in data/code/tests; Exposed removed likewise
- [ ] Feint on a Guarded target: target Open; its next Guard resolves without making it Guarded (consumed); after that, Guard works normally
- [ ] Feint on an Open target: its next Guard still fails (test both cases)
- [ ] Test: player Feint vs a guard×3 enemy, then the player's next Strike lands full damage
- [ ] Save with an old in-flight combat dict containing lure fields loads cleanly
- [ ] REFERENCE §3.7b Moves table updated (five moves incl. Leg it); sim re-run, result noted in the commit
