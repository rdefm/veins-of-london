# 03 — A knocked-out fighter keeps their own art

**What to build:** When a fighter with their own art but no KO art is knocked out, they fall as themselves: their hurt pose, or their idle pose if they have no hurt art, sinks, tips and fades exactly as the current fall does. Today they swap to the default fighter sprite as they fall. Applies to Archie, James and any other fighter in the same position. No new art.

- Real KO art, when a fighter has it, is still used.
- A fighter with no art of their own keeps the default sprite throughout, as today.
- A Rewind getting a fighter back up, and holding a fallen pose before it, use the same art.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/combat_stage.gd` (`_sync_band`, `_resolve_action_keyposes`, `_load_default_animations`, `_ko_fall_steps`, `play_ko`, `hold_fallen`, KO-reversed get-up, `FALL_*` constants)
- `data/combat_visuals.json` (`templates`: `archie` has no `ko`; `james` has neither `hit` nor `ko`; template fallback rule in the notes)
- `tests/` (no existing KO pose test; add one)
- `docs/combat-animation-vision.md` §4.1

**Status:** ready-for-agent

- [ ] Archie falls using his hurt pose; no default sprite at any point
- [ ] James falls using his idle pose
- [ ] A fighter with real KO art uses it; a fighter with no art of their own is unchanged
- [ ] Rewind get-up and held fallen pose match the fall
- [ ] Tests cover each fallback case
- [ ] Data notes describing the fallback match the new rule
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists on-device checks (Archie KO in the Nick fight, a James KO, a default-sprite enemy KO, a Rewind after an Archie KO)
