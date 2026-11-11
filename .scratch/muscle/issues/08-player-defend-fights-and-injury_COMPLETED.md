# 08 — Player defend fights and injury

**What to build:** In a player defend fight (HQ alarm defend, vein defend), the place's posted guards fight beside the player from round 1. Each guard ally's stats = the `guardAlly` block × level weight × trait multipliers (Brawler, Solid, Hothead, Glass jaw), rounded; the combatant shows the guard's short name and level. Every guard who fought earns +3 XP, win or lose. A guard ally knocked to 0 HP is **Injured** for 3 days (1 with Hard to keep down): dropped to Reserve, can't be posted or trained, still paid, no passive XP, tagged "Injured · Nd" in lists. The daily tick counts injuries down. A repel never injures. No deaths.

**Blocked by:** 06 — XP, levels, training and the Muscle daily tick.

**Relevant files:**
- `systems/combat.gd` (`_add_guard_allies`, `build_guard_ally`, `start_raid` ally path), `systems/combat_rounds.gd` (ally end-of-fight results), `systems/home.gd` (`trigger_defend`, `resolve_defend_outcome`), `systems/raiding.gd` (vein defend)
- `systems/muscle.gd` (`injure`, `award_xp`, `daily_tick`)
- `scenes/screens/combat_rounds.gd`, `scenes/components/turn_order_strip.gd`, `scenes/components/combat_stage.gd` (name/level)
- Security screen (Injured tag, blocked actions)
- Tests: `tests/test_combat_rounds.gd`, `tests/test_combat.gd`, `tests/test_home.gd`, `tests/test_muscle.gd`
- REFERENCE.md §3.8 (alarm defend)

**Status:** ready-for-agent

- [ ] Posted available guards appear as round-1 allies; all-L1 no-trait ally stats equal today's
- [ ] Ally stats scale by weight and trait multipliers; name + level on the combatant
- [ ] KO → injured 3 days (1 with Hard to keep down), moved to Reserve, unpostable/untrainable, still billed
- [ ] +3 XP to every guard who fought, win or lose
- [ ] Repel never injures
- [ ] On-device check listed: ally names/levels in fight, Injured tag and countdown
