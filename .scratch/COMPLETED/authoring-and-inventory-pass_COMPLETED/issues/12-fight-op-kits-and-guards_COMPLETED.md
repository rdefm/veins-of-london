# 12 — Fight op kits and guards

**What to build:** The fight op gains its remaining modes. A group can size itself from the vein, as `guards: "vein"` does today, including this event's guard adjustment. Kit mode `guardKit` uses the real kit at the vein or stockpile and spends it under existing raid settlement rules. Kit mode `custom` applies one shared authored kit of items and tiers, is free and touches no stock. The op also accepts existing alert-driven waves and `situational` mods where they apply.

**Blocked by:** 09, 11

**Relevant files:** `systems/events.gd`, `systems/combat.gd`, `systems/guard_kit.gd`, `systems/raiding.gd`, `systems/raid_alarms.gd`, `autoload/GameData.gd`, `tests/test_scripted_fight.gd`, `tests/test_raid_alarms.gd`, `tests/test_raiding.gd`, REFERENCE.md §3.7b Open/Guarded round combat

**Status:** ready-for-agent

- [ ] Vein-sized groups include this event's guard adjustment
- [ ] `guardKit` spends real kit at a vein and at a stockpile
- [ ] `custom` applies its kit and changes no stock
- [ ] Per-enemy loadouts are rejected
- [ ] Alert waves and `situational` mods work on the op
- [ ] Tests cover all three kit modes in vein and non-vein events where valid
- [ ] REFERENCE.md is updated
