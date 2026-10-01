# 14 — Intel meters

**What to build:** Every observer→target pair holds an **intel meter** (0–100): the player on each faction, and each faction on the player and on each other. Levels unlock in order at 20/40/60/80/100: vein security → holdings → stockpile location → stockpile security → stash detail. Scouting and raiding the target raise the meter, and it decays slowly each day. A stockpile relocation drops observers below the location level. The Factions app shows the player's intel level on each faction and what it reveals. Hidden values stay hidden below their level.

**Blocked by:** 02 — Relation clamp + stances.

**Relevant files:** new `systems/intel.gd` (or an expansion of `systems/network_handler.gd`; the ticket decides), `systems/raiding.gd` / scouting paths, `systems/faction_sim.gd` (`pick_stockpile`), `systems/time_system.gd`, `data/constants.json`, `SaveManager`, `scenes/phone_apps/factions_app.gd`, `tests/test_intel.gd` (new), `CONTEXT.md` (intel level), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 82–85, §Intel. REFERENCE.md §3.1, §6.

**Status:** ready-for-agent

- [ ] The intel matrix is in state and backfilled on old saves.
- [ ] Rollover test: meters decay. Test: a raid or scout on a faction raises the player's meter on it.
- [ ] Test: relocating a stockpile drops observers below the location level.
- [ ] The Factions app shows the level plus revealed info per level (vein security, holdings, stockpile location/security, stash).
- [ ] Levels and decay in JSON. CONTEXT, REFERENCE and CODEMAP updated.
