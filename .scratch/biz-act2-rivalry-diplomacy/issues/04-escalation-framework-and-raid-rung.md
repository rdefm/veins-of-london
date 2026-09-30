# 04 — Escalation framework + raid rung

**What to build:** Factions act on pressure through archetype-specific menus gated by relation bands. The bands are warning (< +20), market moves (< 0), and the raid rung (Hostile, or relation below the faction's `raidThreshold`). Before its first move in a new band a faction always sends a warning. It picks the affordable move with the highest expected damage, and makes one move per target per cooldown. Moves are blocked between truce parties (hook only; ticket 09 fills it) and for the held Collective–Firm pair. This ticket delivers the framework, warnings and the raid rung only. The raid rung replaces the old daily rivalry initiation roll and the player-raid gate / worst-relation attacker pick. It reuses the existing rivalry and raid resolvers, with raids queued for the next rollover's resolution. Every move against the player is sent by the faction's key member, logged in the activity log and listed in BizBrief's "moves against you". Archie explains a move type the first time the player suffers it. A vein taken between factions becomes a Ticker headline.

**Blocked by:** 03 — Pressure + relation drift.

**Relevant files:** `systems/faction_ai.gd`, `systems/factions.gd` (`roll_rivalry_attempts`, `_initiation_chance`, `apply_rivalry_resolution`), `systems/raiding.gd` (`roll_raid_attempts`, `_attacking_faction`, `_pick_worst_relation_faction`, `_faction_will_attempt_raids`), `systems/time_system.gd`, `systems/barometer.gd` (headlines), `systems/messages.gd`, `data/constants.json` (menus, bands, cooldowns, costs), `scenes/phone_apps/bizbrief_app.gd`, `scenes/phone_apps/factions_app.gd`, `tests/test_faction_ai.gd`, `tests/test_factions.gd`, `tests/test_raiding.gd`, `tests/test_raid_alarms.gd`, `tests/test_collective.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 20, 25–28, 36–41, §Escalation menus, §Raiding, §Factions. REFERENCE.md §1.8, §1.9, §3.1, §3.12.

**Status:** ready-for-agent

- [ ] The old rivalry initiation roll and worst-relation fallback are removed. Faction-vs-faction and faction-vs-player raids come only from the menu's raid rung.
- [ ] Rollover test: a warning message from the key member precedes the first move in each new band, and the warning flag is stored per observer→target.
- [ ] Rollover test: the cooldown stops a second move against the same target within N days.
- [ ] Rollover test: at Hostile or below `raidThreshold`, a raid is queued and resolves on the next rollover through the existing resolvers. Above that band no raid happens.
- [ ] Moves are skipped for the Collective–Firm pair while the questline is incomplete. The collective-act2 tests pass unchanged.
- [ ] Every move against the player adds an activity-log entry and a BizBrief entry and names the actor. Archie's first-time explainer fires once per move type.
- [ ] A faction-vs-faction vein capture adds a Ticker headline.
- [ ] Menus, bands, cooldowns and move costs are in JSON. REFERENCE §3.1/§3.12 updated (gate + step numbers). CODEMAP updated. `PROSE-REVIEW:` covers warnings per archetype, explainers and headlines.
