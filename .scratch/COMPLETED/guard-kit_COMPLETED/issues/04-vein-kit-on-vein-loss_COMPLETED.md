# 04 — Vein kit on vein loss

**What to build:** A player vein's kit follows the vein's fate.
- A raid that claims the vein moves the whole kit (active or not) into the attacking faction's `holdings.items` at its tiers. The claim notification adds "They took the guard kit." when the kit was non-empty.
- Any other path that removes a vein from `player.veins` returns the kit to inventory: sale to a faction, collapse, or Hakim-site ruin.
- A loot outcome and guards walking both leave the kit on the vein.

**Blocked by:** 01 — Guard kit core.

**Relevant files:** `systems/raiding.gd` (`resolve_raid_outcome`, claim branch ~line 403), `systems/vein_trade.gd` (`sell_to_faction`, ~line 61), `systems/cultivating.gd` (`collapse_vein` level-1 removal, ~line 540), `systems/collective.gd` (`ruin_hakim_site`, ~line 637), `systems/faction_sim.gd` (holdings `items` shape `{recipeKey: {"<tier>": n}}`), `systems/guard_upkeep.gd` (drop rule), tests: raiding, vein_trade, cultivating, guard_upkeep. Spec §Loss. REFERENCE.md §3.12.

**Status:** ready-for-agent

- [ ] A claim adds every kit unit to the attacker's holdings at the same tiers. The new faction vein has no `factionVein.kit` from it, and the notification line is added (PROSE-REVIEW).
- [ ] Sale, collapse and Hakim ruin each return the kit to `player.inventory` at its tiers.
- [ ] Loot and guards walking leave the kit untouched.
- [ ] REFERENCE §3.12 is updated.
