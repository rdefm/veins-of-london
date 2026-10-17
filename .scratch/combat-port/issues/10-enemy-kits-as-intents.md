# 10 — Enemy, guard and raider kits as planned intents

**What to build:** Enemies carrying items (enemy capabilities, faction raider kits) and guard allies carrying guard kits use them as actions in their committed round plans, per §3.7b. Enemy kit actions show on the strip as intents, subject to fog like any other enemy action. Kit capacity, consumption and refill rules are unchanged.

**Blocked by:** 05, 06

**Relevant files:** `systems/combat.gd` (`_enemy_capabilities_from_template`, `_enemy_try_item`, `_guard_try_item`, `_guard_pool_has`, `_spend_guard_item`); `systems/combat_prototype.gd` (plan rolling); `systems/raiding.gd`; `data/factions.json`; `data/enemies.json`; `tests/test_combat.gd`; `tests/test_raiding.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] An enemy with a kit item commits it in its plan and it resolves at its slot
- [ ] Unread kit intents show `?` until they resolve
- [ ] Guard kits spend and refill as today
