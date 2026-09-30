# 17 — Player stockpile raids

**What to build:** Once the player's intel on a faction reaches the location level, its stockpile shows as a raid-target pin in its district. The raid runs through the existing raid flow against stockpile guards and faction kit. Stockpile guards are paid upkeep by the faction, as for vein guards. Success steals a share of holdings, capped by carry. With stash-level intel a success can wipe the holdings. Any stockpile raid is a large relation hit and a hostile act (war clock), and the stockpile then relocates.

**Blocked by:** 08 — War + weariness; 14 — Intel meters.

**Relevant files:** `systems/raiding.gd` (`begin_raid`, resolution), `systems/faction_sim.gd` (`pick_stockpile`, holdings), `systems/guard_upkeep.gd`, `systems/guard_kit.gd` / `raider_kit`, `systems/map_pins.gd`, `systems/intel.gd`, `data/constants.json` (loot shares, stockpile guards), `SaveManager`, `tests/test_raiding.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 94–99, §Stockpile raids. REFERENCE.md §3.12.

**Status:** ready-for-agent

- [ ] The stockpile pin appears only at ≥ location-level intel.
- [ ] Test: a successful raid moves a capped share of faction holdings to the player. With stash intel it can wipe the stores.
- [ ] Test: the raid drops relation heavily, starts or extends a war, and relocates the stockpile, which drops the player's intel below the location level.
- [ ] Stockpile guards cost the faction upkeep. REFERENCE and CODEMAP updated.
