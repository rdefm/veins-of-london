# 12 — Faction losses and raid wiring

**What to build:** What the player scouts is what they fight. A raid's starting enemy guards = that vein's posted counts by level (stockpile raid: stockpile counts), and enemy guard combatants show their level. A faction guard defeated in a player raid fight is out 3 days, then returns to that faction's Reserve. A vein the player takes sends its faction guards to the faction's Reserve. Rivalry: the losing side of an attempt loses 1 guard to injury (the raided vein's posts on success, the attacker's Reserve on failure). The faction daily tick returns injured guards.

When the reinforcement clock fires, up to `reserveResponders` (2) come from the owner faction's Reserve, highest level first — fewer or none if the Reserve is empty or already answered this block. Zero → the event's "No one came." variant card if the event authors one, else the arrival card is skipped. Authoring variant cards is event-writing work, not this ticket. Sites with no owner faction keep the event's flat +2.

**Blocked by:** 11 — Faction muscle counts; 08 — Player defend fights and injury.

**Relevant files:**
- `systems/muscle.gd` (`faction_injure`, `faction_draw_reinforcements`, `faction_daily_tick`)
- `systems/events.gd` (`_maybe_start_reinforcement_clock`, `_tick_reinforcement`, `reinforcements_arrived`), `systems/combat.gd` (`generate_raid_enemy`, `_spawn_guard_instance`, `start_raid`, `start_stockpile_raid`), `systems/combat_rounds.gd`, `systems/raiding.gd` (`resolve_stockpile_fight`, vein capture), `systems/faction_ai.gd`, `systems/warmonger.gd` (rivalry resolution), `systems/faction_sim.gd`
- `data/events/` raid events (yard, arches, shop) — read only
- Tests: `tests/test_raiding.gd`, `tests/test_raid_arches.gd`, `tests/test_raid_shop.gd`, `tests/test_vein_raid_yard.gd`, `tests/test_faction_sim.gd`, `tests/test_combat_rounds.gd`, `tests/test_event_fight.gd`
- REFERENCE.md §3.12 (vein raiding/reinforcements)

**Status:** ready-for-agent

- [ ] Raid enemy count and levels match the vein's posted counts (stockpile raid: stockpile counts)
- [ ] Enemy guard level shown on the combatant
- [ ] Defeated faction guards out 3 days then back in Reserve; a captured vein's guards go to the faction Reserve
- [ ] Rivalry injures 1 guard on the losing side
- [ ] Reinforcement draw: ≤2, highest level first; empty or busy Reserve → none; variant card used if authored, else arrival card skipped
- [ ] Ownerless sites keep flat +2
- [ ] Event tests address cards by key; card-walk loops capped
