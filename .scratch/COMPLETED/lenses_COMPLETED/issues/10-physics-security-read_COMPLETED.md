# 10 — Physics lens: raid site security read

**What to build:** Spec `.scratch/lenses/spec.md` "Physics: security read". With a Physics lens and Sense >= world gate, the player's effective intel on any faction counts one level higher on the vein-security track only (`Intel.knows`/`level` for that level id), so the raid site sheet shows guard kit and ward type through the existing intel display. The stored meter is not raised.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/intel.gd`
- `systems/lenses.gd`
- `scenes/screens/map.gd`
- `data/factions.json`
- `tests/test_intel*.gd`
- `docs/REFERENCE.md` §3.12 (Wards, Security profile) + intel section

**Acceptance:**
- [ ] `knows(player, faction, vein security)` true one level early with lens; other levels and the meter value unchanged.
- [ ] Raid site sheet shows guard kit + ward with lens (human QA).
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
