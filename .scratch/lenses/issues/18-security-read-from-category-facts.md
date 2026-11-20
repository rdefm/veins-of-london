# 18 — Prefactor: vein security read built from per-category facts

**What to build:** The raid site sheet's Alarms / Ward / Guards rows are built from five separate security facts about a faction vein:
- alarms/cameras
- guard count
- guard strength
- guard kit
- ward

Each fact is either known (with its value) or unknown. Every unknown fact renders as the unknown mark. The player sees no change: today a fact is known for all five or none, depending on the vein-security intel level, and the Physics lens read still works as now. This makes the change easy for 19, which only has to supply facts from a different source.

Guards row rendering, which every later ticket relies on:
- Count known and 0 → `None`.
- Otherwise the parts are joined with ` · `: count (`? guards` when unknown), strength (`?` when unknown), and kit (`kit: ?` when unknown).
- All three unknown → the unknown mark alone.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/intel.gd`: `vein_security_read`, `_guards_text`, `knows`
- `systems/raiding.gd`: `security_profile`
- `systems/guard_kit.gd`: `unit_count`
- `scenes/screens/map.gd`: `_build_faction_vein_content` (consumer, should not change)
- `data/constants.json`: `intel.securityRead`
- `tests/test_intel.gd`
- REFERENCE.md §3.1 "Intel", §3.12 "Security profile"
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] The security read takes five per-category facts, each known or unknown; the faction-wide vein-security level marks all five known.
- [ ] Output identical to today at and below the vein-security level, and with the Physics lens read (existing tests pass unchanged).
- [ ] New tests cover mixed known/unknown facts, including the Guards row cases above.
- [ ] Syntax check clean, tests pass, CODEMAP updated if responsibilities shift.
