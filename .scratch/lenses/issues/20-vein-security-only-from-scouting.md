# 20 — Vein security comes only from scouting

**What to build:** High faction intel no longer reveals every vein's security. The vein-security intel level is removed; the ladder becomes holdings → stockpile location → stockpile security → stash detail, at their current thresholds.

- **Map sheet:** the Alarms / Ward / Guards rows show only fresh scouted facts. At any intel value, a fact that hasn't been scouted reads `?`.
- **Physics lens:** its old "+1 intel level" vein-security read goes away. Its replacement arrives in 21.
- **File a complaint:** available against a faction vein only when the player has at least one fresh scouted fact on that vein. Otherwise it is refused with a short reason.
- **Factions app intel tab:** the "Veins: N Warded…" summary becomes "Veins scouted: N of M". N counts that faction's veins with at least one fresh fact; M is its total site veins.
- **Docs:** update the CONTEXT.md "Intel level" entry and the lenses spec's Physics row.

**Blocked by:** 19

**Relevant files:**
- `data/constants.json`: `intel.levels`
- `systems/intel.gd`: `knows`, `level`, `physics_read`, `vein_security_read`, `vein_security_counts`
- `systems/player_moves.gd`: `intelGate` handling
- `data/player_moves.json`: `fileComplaint`
- `scenes/phone_apps/factions_app.gd`: `_build_intel`
- `tests/test_intel.gd`, plus player-moves tests
- `CONTEXT.md` ("Intel level"), `.scratch/lenses/spec.md` ("Physics — security read"), `CODEMAP.md`
- REFERENCE.md §1.11 "Intel", §3.1 "Intel", §1.4 Lenses

**Status:** ready-for-agent

- [ ] At max intel without a scout, every security row reads `?`. Holdings and higher levels unlock as before.
- [ ] File a complaint is refused on an unscouted vein or one with only stale facts, and allowed with at least one fresh fact.
- [ ] The Factions app shows "Veins scouted: N of M".
- [ ] No reference to the vein-security level remains in code or data (grep `veinSecurity`).
- [ ] Human QA: Factions app intel line, File a complaint availability. PROSE-REVIEW: refusal reason and new app line.
- [ ] Syntax check clean, tests pass, REFERENCE/CONTEXT/spec/CODEMAP updated.
