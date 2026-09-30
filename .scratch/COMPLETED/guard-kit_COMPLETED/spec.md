# Guard kit — items assigned to a vein's guards

Status: ready-for-agent

> Builds on `.scratch/biz-act2-guard-upkeep/spec.md` (guard counting, drop rule, guard repel) and the faction per-vein kit from biz-act2-faction-economy (REFERENCE §1.8 "Per-vein kit allocation"). The player can stock a guarded vein with combat consumables. Guards use them when the player defends the vein in person, and they strengthen the guards' repel roll when the player doesn't turn up. Numbers marked *placeholder* are feel targets. The tuning pass pins them in JSON and REFERENCE.md.

## Problem Statement

A player's guards are abstract. They add raid resist and roll to repel a raid the player misses, but they never appear in the defence fight itself. The player fights with contacts only, and the guards they pay £500 a week for stand aside. There's also nothing a player can do to make one vein's guards better than another's except hire more of them. Factions already give their veins a defend kit, but the player can't do the same.

## Solution

- **Guard kit.** The player assigns combat consumables from their inventory to a guarded vein. The items leave the inventory and sit on the vein. Unassigning returns them.
- **Capacity.** Each guard gives the vein a fixed number of kit slots (`slotsPerGuard`, *placeholder* 2).
- **Defending in person.** The vein's guards join the defend fight as allies, after contacts, up to the ally cap of 3. On each guard's turn, if a kit item applies, the guard uses it instead of attacking. The player can't use the vein kit themselves.
- **Not defending.** Kit items add to the guards' repel chance, with a higher cap. The repel roll uses up one of each item type in the kit, whether it works or not.
- **Assigning.** A "Guard kit" row on the vein detail panel opens a stocking sheet built on the Trade sheet pattern. An HQ Guard Kit screen lists every guarded vein's kit for restocking.
- **Loss.** A raid that claims the vein hands the kit to the attacking faction. Selling the vein or its collapse returns the kit to the player. Guards walking leave the kit on the vein, where it does nothing until a guard is hired again.

## User Stories

### Assigning
1. As a player, I want to stock a guarded vein with combat consumables from my inventory, so that its guards are better equipped.
2. As a player, I want assigned items to leave my inventory, so that I can't spend or sell them by accident.
3. As a player, I want to take items back off a vein at any time, so that stocking a vein isn't a trap.
4. As a player, I want to choose which quality tier goes to a vein, so that I decide whether my guards get my best items.
5. As a player, I want each guard to add kit slots, so that more guards can carry more kit.
6. As a player, I want the vein sheet to show the kit and slots used (e.g. "Guard kit 3/4"), so that I can see how a vein is equipped at a glance.
7. As a player, I want one HQ screen listing every guarded vein's kit, so that I can restock after raids without visiting each vein.
8. As a player, I want the kit row disabled on a vein with no guards, so that I don't stock a vein nobody defends.
9. As a player, I want only items guards can actually use to be offered, so that I don't waste an item.

### Defending in person
10. As a player defending my vein, I want its guards to fight beside me, so that the guards I pay for actually show up.
11. As a player, I want contacts to join first and guards to fill the rest of the ally slots up to 3, so that the fight stays readable.
12. As a player, I want guards to use the vein's kit sensibly (heal the hurt, shield, blast, freeze), so that the kit makes a visible difference.
13. As a player, I want to fight with my own inventory while guards use the vein kit, so that the two pools stay separate.
14. As a player, I want a guard KO'd in a fight to be back on duty afterwards, so that losing a fight doesn't also cost me guards.
15. As a player, I want items guards use in a fight to be gone from the vein kit, so that the kit is a real resource.

### Not defending
16. As a player who misses a defence, I want the vein's kit to raise its guards' repel chance, so that stocking a vein helps even when I'm away.
17. As a player, I want the repel roll to use up some kit, so that kit protection has a cost.
18. As a player whose guards fail to repel, I want the rest of the kit to stay on the vein (if it's still mine), so that I only lose what was used.

### Loss and edge cases
19. As a player whose vein is claimed by a raid, I want to know the attacker took its kit, so that the stakes of stocking a vein are clear.
20. As a player who sells a vein or sees it collapse, I want its kit back in my inventory, so that I don't lose items for no reason.
21. As a player whose guards walk, I want the kit to stay on the vein, so that I can rehire and carry on.
22. As a player whose vein has fewer slots after guards walk, I want the extra kit kept but not counted, so that nothing vanishes without me deciding.

### Save and rewind
23. As a player with an old save, I want my veins to start with an empty kit, so that updating changes nothing.
24. As a player, I want Rewind to restore vein kits exactly, so that time travel stays consistent.

## Implementation Decisions

### Eligible items
- Allowlist in JSON (`guardKit.items`): `blast`, `shield`, `blackHole`, `timePearl`, `healingBurst`, `prophetsBreath`, `enhancementPowder`, `failsafe`, `rewind`.
- Not eligible:
  - `wormhole`: guards don't flee.
  - `healingSalve`: not usable in fights.
  - `pansPrank`, `beALady`, `rejuvenation`: no combat effect.
- The stocking sheet offers only allowlisted items.

### State (pure data)
- `vein.guardKit = { recipeKey: { "<tier>": count } }` on player veins. It has the same tier-bucketed shape as `player.inventory` (REFERENCE §2), and `{}` means empty.
- SaveManager backfills `{}` on old saves.
- Faction veins keep their own `factionVein.kit`, unchanged.
- No per-guard state is added. A guard ally in a fight is a snapshot inside `combat.allies`, like contacts.

### Capacity
- `capacity(vein) = Cultivating.vein_guard_count(vein) × guardKit.slotsPerGuard` (*placeholder* 2).
- Each item unit takes one slot.
- **Over capacity** (guards walked, or a tier guard was dropped): the kit is kept.
  - Only the first `capacity` units are active, in the order of the allowlist and then tier, highest tier first.
  - Inactive units can't be used in fights and don't count for repel.
  - Stocking is refused while the kit is at or over capacity. Returning items is always allowed.
- With 0 guards the whole kit is inactive and the row shows it as idle.

### Stocking system (`systems/guard_kit.gd`, static)
- `GuardKit.stock(veinId, recipeKey, tier, qty)`:
  - Moves `qty` units of that tier from `player.inventory` into `vein.guardKit`.
  - Refused with no change if: the item isn't allowlisted, the player holds fewer than `qty` at that tier, the vein isn't the player's, the vein has 0 guards, or the kit would go over capacity.
- `GuardKit.unstock(veinId, recipeKey, tier, qty)`: moves units back to `player.inventory`. Refused if the kit holds fewer than `qty`.
- Both emit `EventBus.state_changed`. Screens only call these, never edit the kit themselves.
- `GuardKit.active_units(vein)` returns the active part of the kit, per §Capacity.

### UI
- **Vein detail panel** (`vein_detail_panel.gd`): a "Guard kit n/cap" row under Security, with a short summary (e.g. "Shield ×2 · Blast ×1"). It's disabled with 0 guards and marked idle when over capacity. Tapping it opens the stocking sheet.
- **Stocking sheet:**
  - Uses the Trade sheet pattern (`sell_menu_view.gd`): grouped item tiers, one stepper per tier, sticky totals, a review step.
  - Two tabs: **Stock** (from inventory) and **Return** (to inventory).
  - The totals bar shows slots used / capacity.
  - Confirming calls `GuardKit.stock` / `unstock` for each changed line.
  - A new view or a mode of the Trade sheet, whichever the ticket finds cleaner. The pattern is what matters, not sharing the code.
- **HQ Guard Kit screen:** lists every player vein with 1+ guards, or with a non-empty kit, showing its kit, slots and idle state. Tapping a row opens that vein's stocking sheet. It's reached from the HQ security zone (`hq_door.gd`, next to the guard tile). The ticket confirms the exact entry point.
- All new UI strings are flagged PROSE-REVIEW.

### Defend fight — guards as allies
- In `Combat.start_defend_vein`, after `_gather_defend_allies` (contacts), guards fill `combat.allies` up to `SQUAD_MAX` (3) in total. There's one guard ally per guard on the vein (`vein_guard_count`).
- **Guard ally:** a generic "Hired Guard" ally snapshot. Its stats (hp, attack range, speed) come from JSON (`guardKit.guardAlly`, *placeholder*) and it has the same shape as `Contacts.build_combat_ally` output, with a `guardAlly: true` marker and no `contactId`.
- **Kit pool:**
  - The vein's active kit is copied into `combat.guardKit = { items: {recipeKey: {tier: n}}, used: {recipeKey: {tier: n}} }` at fight start. It's a shared pool for all guard allies and is spent highest tier first.
  - Each spend moves 1 unit from `items` to `used`.
  - Item power = `effectPower[tier]`.
- **Guard turn:** the first rule that applies uses one item instead of attacking. Otherwise the guard attacks as normal.
  1. `rewind`: if the player's hp would hit 0, a guard rewinds the fight. This follows the ally-rewind rule (`_try_ally_rewind`, James precedent) and is tried after the player's own Failsafe/Rewind.
  2. `healingBurst`: heal the most hurt of the player and living allies below `ALLY_HEAL_THRESHOLD_FRACTION` (0.4), capped at hpMax.
  3. `prophetsBreath`: if the player is below 0.4 hp and has no evade active, give the player evade turns (same fields as the player's own use).
  4. `shield`: shield the most hurt of the player and living guard allies whose `shieldPool` is 0.
  5. `blackHole`: if 2+ enemies are alive and none are frozen, damage one and freeze, as the player's use does.
  6. `timePearl`: same trigger as Black Hole, freeze only.
  7. `blast`: damage the living enemy with the lowest hp.
  8. `enhancementPowder`: once per guard per fight, boost that guard's own attack. The boost reuses the player's effect with the guard as the target, and the ticket pins the exact mapping.
- **`failsafe`:** used automatically, not on a turn. A guard ally that would be KO'd survives once at 1 hp if a failsafe is in the pool.
- **The player can't use `combat.guardKit`.** The player's item menu reads `player.inventory` only.
- **Guard KO:** the guard is out for the rest of the fight with no lasting effect, no walk and no cooldown.
- **After the fight** (win, loss or flee): `exit_combat()` takes `used` off `vein.guardKit`, win or lose. If a lost fight results in a claim, the rest of the kit goes to the attacker (§Loss).
- **Rewind** does not refund guard kit items, matching raider kits (REFERENCE §3.7 Raider kits).
- New combat log lines are flagged PROSE-REVIEW. Beats reuse the ally item beat types with `effectKey`.

### Not defending — repel boost
- This applies wherever a player vein's guards roll repel: the missed-defend window and Leave undefended (`Raiding._guards_repel_defend_raid`, REFERENCE §3.12).
- **Chance:** `min(guard_repel_chance(count) + Σ kit bonus, cap)`.
  - Kit bonus: each active item *type* adds its strength once. Strengths come from JSON (`guardKit.repelBonus` = `{weak, medium, strong}`, *placeholder* 0.03 / 0.05 / 0.08).
    - weak: `healingBurst`, `prophetsBreath`, `enhancementPowder`, `failsafe`
    - medium: `shield`, `blast`
    - strong: `blackHole`, `timePearl`, `rewind`
  - `cap` = `guardKit.repelCap` (*placeholder* 0.90) when the vein has 1+ active kit item. Otherwise it's the existing `guardRepel.cap` (0.75).
- **Cost:** one unit of each active item type is used up on the roll, highest tier first, whether the repel works or not.
- 0 guards means no roll (unchanged), and the kit is untouched.
- The repel notification is unchanged. A repel where kit was used adds "They went through <items>." (PROSE-REVIEW).
- Faction repel is unchanged. This spec doesn't touch `factionVein.kit`.

### Loss
- **Claim** (`Raiding.resolve_raid_outcome` claim branch): the vein's whole `guardKit` (active or not) moves into the attacking faction's `holdings.items` at its tiers. The claim notification adds "They took the guard kit." when the kit was non-empty (PROSE-REVIEW). The new faction vein starts with no `factionVein.kit` from it. The faction's own `allocate_kits` handles the vein from the next rollover.
- **Loot:** the kit stays, minus anything used in the repel or fight.
- **Sold or collapsed** (any path that removes a vein from `player.veins` other than a claim): the kit returns to `player.inventory` at its tiers.
- **Guards walk** (short pay or drop): the kit stays and becomes inactive past capacity.

### Data (JSON, none in code)
- `constants.json` `guardKit`:
  - `items` (allowlist)
  - `slotsPerGuard`
  - `repelBonus {weak, medium, strong}`
  - `repelTier {recipeKey: "weak"|"medium"|"strong"}`
  - `repelCap`
  - `guardAlly {name, hpMax, attackMin, attackMax, speed}`

### REFERENCE.md updates
- §1.6 vein security: guard kit, capacity, repel boost.
- §2 state: `vein.guardKit`, `combat.guardKit`.
- §3.7 / §3.7a combat: guard allies, guard turn rules, kit spend, failsafe.
- §3.12 raiding: missed-defend repel with kit; claim transfers the kit.

## Testing Decisions

- Assert external behaviour only. Seed `GameState.state`, drive a public entry point, and assert the resulting state.
- **Stocking** (`GuardKit.stock` / `unstock`): moves units between inventory and kit by tier. Refused for: an item not on the allowlist, `healingSalve`, 0 guards, over capacity, not enough held. Return is always allowed.
- **Capacity:** dropping a guard leaves the kit intact but makes units inactive. Stocking is refused while over capacity.
- **Defend fight** (seeded Rng):
  - Guards join after contacts, up to 3 allies in total.
  - Each guard rule fires on its trigger and spends the highest tier first.
  - The player's item menu doesn't list kit items.
  - Failsafe saves a guard once.
  - `exit_combat` takes `used` off the vein kit, win or lose.
  - A KO'd guard is still counted by `vein_guard_count` afterwards.
- **Missed defend** (seeded Rng):
  - Kit raises the repel chance by type strength, with the raised cap.
  - One unit of each active type is used, win or lose.
  - 0 guards means no roll and no kit spent.
- **Loss:** a claim moves the kit into faction holdings. Selling or collapse returns it to the inventory. Guards walking keep it.
- **Save:** the kit round-trips, and an old save gets `{}`.
- **Prior art:**
  - combat tests: ally combat, raider kit items, ally Dial
  - raiding tests: guard repel, missed defend, claim/loot
  - guard_upkeep tests: drop rule
  - crafting tests: tiered inventory
- Suite discipline: one targeted run per change, and one full suite + check_all at the end.

## Out of Scope

- The player using vein kit items in a fight.
- Factions reacting to a vein's kit (sub-spec 4a), or raiders targeting kit.
- Automatic restocking, or a "keep stocked" target.
- Guard injuries or any lasting effect of a KO.
- Per-guard stats, levels or names.
- Wormhole, Healing Salve, Pan's Prank, Be a Lady and Rejuvenation in the kit.

## Further Notes

- A defend fight with 3+ guards and no contacts puts 3 guard allies on screen. Worth a UI check on-device.
- The repel strengths and the 0.90 cap make a fully stocked vein with 4+ guards nearly raid-proof when the player is away. The per-roll cost is what balances that. Watch it in the tuning tool.
- Only the vein detail panel, the stocking sheet and the HQ Guard Kit screen are new UI. Everything else reuses existing sheets and combat beats.

## Decisions (ticketing, 2026-09-29)

- **Tier 0 items** ("no known quality", from events/purchases) power as tier 1 when a guard uses them (`effectPower[max(tier, 1)]`). Spend order stays highest tier first, so tier 0 goes last.
- **Guard Rewind** fires on each would-be player KO, 1 unit per fire, for as long as the pool has a rewind. There's no per-guard or per-fight limit.
- **Guard Enhancement Powder:** once per guard per fight, the guard ally gets its own `motionTurns`/`motionPower`, with the player's formula (`motionTurns = 2 if power >= 3 else 1`). Its extra attack entries join the round queue from the next round.

## HQ guard kit

HQ guards (`Home.get_guard_count()`) get a kit too, built the same way as a vein's.

- **State:** `home.guardKit`, with the same tier-bucketed shape as `vein.guardKit`. SaveManager backfills `{}`.
- **Capacity:** `Home.get_guard_count() × guardKit.hqSlotsPerGuard` (*placeholder* 3). The allowlist, over-capacity, idle and stocking rules match §Capacity and §Stocking system.
- **Config:** the one `guardKit` block is reused (allowlist, repel strengths, `repelCap`, `guardAlly`), plus `hqSlotsPerGuard`.
- **UI:** an HQ row at the top of the HQ Guard Kit screen and a kit row in the HQ security zone. Both open the shared stocking sheet.
- **Missed defend:** `Home._guards_repel_pending_raid` gets the same kit bonus, raised cap and one-per-active-type cost as §Not defending.
- **Alarm-defend fight** (`Combat.start_home_alarm_defend_combat`): HQ guards join as guard allies, up to `SQUAD_MAX`, and use `home.guardKit` under the §Defend fight rules. `exit_combat` takes `used` off `home.guardKit`. The scripted tutorial `home_raid` fight is unchanged.
- **Loss:** a successful HQ raid leaves the kit in place. Only units used by the repel roll or in the fight are lost, and raid loss stays ore-only. Guards walking keeps the kit, which goes inactive past capacity.
