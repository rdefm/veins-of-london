# 07 — Staff tier from the staffer's own level; fixed staff calc

**What to build:** Lab staff keep crafting toward Production targets with their existing speciality eligibility and chance roll, but the tier of what they make now comes from the staffer's own crafting level, capped at 4 (data), independent of the player's recipes, best ranks and skill. Staff calc cost uses the same fixed per-recipe base calc as the player. Cost previews elsewhere match. Spec: `.scratch/lab-port/spec.md` § Staff (Rooms).

**Blocked by:** 01

**Relevant files:**
- `systems/rooms.gd` (craft attempt ~L373–412), `tests/test_rooms.gd`
- `systems/contracts.gd` (~L391 `calc_cost`), `systems/daily_brief.gd` (~L379 `calc_cost`)
- `systems/lab.gd` / `data/lab.json` (base calc, staff tier cap)
- `systems/faction_sim.gd` (must stay on the faction curve — don't touch)
- REFERENCE.md §3.5, R§3.10 "Producer"

**Status:** ready-for-agent

- [ ] Staff item tier = staffer crafting level, capped at 4 from data; never 5
- [ ] Tier unaffected by player best rank or player skill (tested)
- [ ] Staff calc = recipe base calc; Contracts and DailyBrief previews use the same
- [ ] Speciality eligibility, targets and chance roll unchanged (existing tests pass)
