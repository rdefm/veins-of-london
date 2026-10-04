# Combat loadouts, Dials, and reinforcements

Status: ready-for-agent
Date: 2026-10-04
Scope: agreed design; no implementation or tickets in this document.

## Problem Statement

Combat currently lets the player use any stocked combat item through the Bag, so carrying an item requires no preparation. Recruited allies cannot be equipped; Archie's self-healing stash replenishes for free; James's Dial has fixed powers and a separate charge system. Vein guards have a two-unit-per-guard kit, HQ guards have three, and enemy raiders share an uncapped squad kit. The Profile app only reports equipment, while the player's Dial loadout is managed at HQ. Fights start through several paths without a consistent chance to inspect the participating squad.

Combat also truncates raid guards to three. More guards or recruits therefore cannot join a fight as reinforcements. The combat UI offers one generic Item action and item text symbols rather than showing the two items the player actually brought.

## Solution

Give the player and each combat-capable recruited ally two physical consumable slots. Manage those slots and each owned Dial from Profile; make the same Dial loadout menu accessible from HQ. Every encounter pauses at a preparation screen. Planned raids and defences commit their travel, time and rolls only after Fight; unavoidable encounters pause after their trigger has committed. The screen shows participants and available stock, permits eligible recruit selection where appropriate, warns when participating player/recruit slots are empty despite available items, and links to Profile focused on the participants. Combat shows the player's two item slots directly, while the Bag is read-only.

Retain the shared kit system for hired guards and faction raiders, at two units per guard or raider in the full roster. Kits draw and replenish from their owner's actual stock. Recruited allies use equipped items and configurable Dials automatically; the player controls only their own item buttons and Dial. Remove player-equippable weapons and Archie's free combat stash heal. Give every crafted consumable a distinct pixel-art icon; these are all already saved in C:\Users\Richard\projects\veins-of-london\assets\combat\icons.

Allow each side three active combatants, **including the player on the friendly side**. Additional combatants wait as reinforcements. A KO brings the next waiting combatant onto the stage; the reinforcement can be targeted immediately and receives an unspent occurrence according to their speed, or waits for the next round if the replaced fighter already acted. The fight ends only when the opposing side's active fighters and reinforcements are defeated. If the player is KO'd, allies continue automatically and can still win.

## User Stories

1. As a player, I want to equip two consumables, so that preparation changes my combat choices.
2. As a player, I want to equip the same consumable twice, so that I can commit two units to one tactic.
3. As a player, I want equipment to leave available inventory when equipped, so that one unit cannot be carried by two people.
4. As a player, I want unused equipment returned on unequip, so that changing plans does not destroy stock.
5. As a player, I want to equip Archie and James, so that recruited allies use supplies I choose.
6. As a player, I want noncombat recruits excluded from combat loadout controls, so that Profile only offers relevant choices.
7. As a player, I want allies to use only their equipped consumables, so that their supplies have an understandable limit.
8. As a player, I want Archie to lose his free self-heal, so that his recovery follows the same equipment rule.
9. As a player, I want automatic ally item use to follow clear triggers and targets, so that I can predict what they will spend.
10. As a player, I want ally Dial casts considered before equipped items, so that the preferred action order is consistent.
11. As a player, I want Wormhole reserved for my own slots, so that an ally cannot flee without my decision.
12. As a player, I want actual item tier to determine equipped item power, so that higher-quality stock matters in combat.
13. As a player, I want consumed slots refilled after a fight when matching stock exists, so that my chosen loadout persists across fights.
14. As a player, I want empty slots to stay empty when stock arrives later, so that new stock does not silently change a failed refill.
15. As a player, I want unused equipped items retained after a KO, flight or loss, so that only spent units disappear.
16. As a player, I want to see both item slots directly in combat, so that I can act without opening an Item menu.
17. As a player, I want empty combat slots displayed as disabled rows, so that I can see what I failed to bring.
18. As a player, I want the Bag to be read-only during combat, so that the two-slot limit cannot be bypassed.
19. As a player, I want event and out-of-combat item actions to use unequipped stock, so that reserved combat items remain reserved.
20. As a player, I want Profile to manage my Dial and recruited characters' Dials, so that loadouts live together.
21. As a player, I want HQ to open that same Dial menu, so that its two entry points cannot disagree.
22. As a player, I want to wind a Dial from either entry point and before a fight, so that I can prepare charge without returning to HQ.
23. As a player, I want James's Dial to use the ordinary Movement, Complication, charge and XP rules, so that it is editable like mine.
24. As a player, I want James ready with a level 2 Dial, tier 1 Recharge Movement and two tier 3 Complications, so that he remains useful on recruitment.
25. As a player, I want Dial level to strengthen loaded Complication casts, so that levelling a Dial changes its effects.
26. As a player, I want timed Complications to show their level-based turn bonuses, so that the result is predictable.
27. As a player, I want every fight to stop at preparation, so that even a mugging lets me inspect my loadout.
28. As a player, I want planned raids and defences to commit only when I press Fight, so that inspecting or changing loadout costs nothing.
29. As a player, I want forced encounters to remain forced after preparation, so that story and trigger consequences are not reversed.
30. As a player, I want to choose and order eligible recruits for raids and defences, so that I decide who fights and who reinforces.
31. As a player, I want scripted encounters to retain their established participants, so that preparation does not summon absent allies.
32. As a player, I want a warning naming participants with empty slots I could fill, so that I can use available stock before Fight.
33. As a player, I want Change loadout to return me to the pending encounter, so that I do not lose its context.
34. As a player, I want guard kits to remain separate from Profile, so that each defence still uses the property's kit.
35. As a player, I want HQ and vein guard kits capped at two units per guard, so that they follow the same capacity rule.
36. As a player, I want spent guard kit types restocked after a defence or unattended repel when inventory allows, so that guards remain supplied.
37. As a player, I want raiders limited to two stocked kit units per raider, so that enemy supplies respect the same bound.
38. As a player, I want enemy kit units selected from actual faction stock by tier, so that faction resources and item quality affect a fight.
39. As a player, I want more than three guards or allies to appear as reinforcements, so that large groups fight without crowding the stage.
40. As a player, I want waiting fighters represented by small, distant sprites, so that I can see who may enter next.
41. As a player, I want only active fighters targetable and affected by area effects, so that reserves are genuinely off the field.
42. As a player, I want a reinforcement to inherit an unspent turn by their own speed, so that entering mid-round respects initiative.
43. As a player, I want victory only after all enemy reinforcements are defeated, so that a hidden reserve cannot be ignored.
44. As a player, I want my allies to continue after I am KO'd, so that their victory still counts as mine.
45. As a player, I want to return at 10% HP after an ally-won fight or loss, so that the KO has a lasting cost.
46. As a player, I want every crafted consumable to have a distinct icon wherever it appears, so that item choices are recognisable at phone size.
47. As an existing player, I want my save converted without duplicated or lost consumables, so that the new loadout and tier rules preserve my stock.

## Implementation Decisions

### State, ownership and item use

- Personal slots exist for the player and recruited contacts with a combat kit. Two slots per eligible character; each holds one unit with recipe and tier. Identical recipes may occupy both. Equipping transfers the exact tiered unit from shared inventory into the slot; unequipping transfers it back. Starting slots are empty on new games and migrated saves.
- Only the established combat-usable consumables may be equipped. Healing Salve remains out-of-combat-only. Failsafe and Rewind occupy personal slots when carried as consumables; loaded Dial Complications remain separate. Rewind from a slot spends that slot; Rewind from a Dial spends charge only. The current Rewind timing and non-refund rule remain.
- Wormhole may be equipped and manually used by the player; recruited ally AI may not equip it. Other ally consumables use the existing guard-kit trigger and target rules where applicable. Self effects apply to the acting ally. Ally order is Dial cast, equipped item, then ordinary attack. Remove Archie's built-in combat stash self-heal and its after-fight replenishment.
- Direct personal consumables use their stored item tier for effect power; tier 0 is retired. Existing tier-0 units in every player, stash, guard, faction and loaded-Dial store convert to tier 1, and future grants that formerly produced tier 0 produce tier 1. Direct item effects do not receive Dial amplification.
- Combat never refills a personal slot mid-fight. At fight settlement, refill a used slot from the highest available tier of the same recipe in shared player inventory, with player before recruited allies in Profile order and slot 1 before slot 2. A never-assigned empty slot has no preferred recipe. If a refill fails, the slot remains empty; later stock acquisition does not auto-refill it. Unused units remain equipped after win, loss, flight or KO. Rewind does not refund item units or Dial charge.
- The Bag cannot use stocked combat items during combat and cannot change loadouts there. Event hooks and out-of-combat actions read unequipped inventory only. All other item selling, business and stash flows must respect equipped units having left available inventory.
- Remove player-equippable weapons and crowbars from state, data and controls; remove existing-save crowbars without compensation. Player attack uses the existing unarmed base and Combat Skill progression (3–7 at level 1). Preserve authored enemy attack stats and enemy weapon bonuses. Run a combat balance check; do not silently invent a compensating damage bonus.

### Guard and faction kits

- Retain shared, tier-bucketed guard kits for player veins and HQ. Capacity is two units times the full number of guards, including guards who wait as reinforcements. The defence still uses its own place's kit, not recruits' personal slots. Reduce HQ from three to two per guard. On migration, return units above HQ capacity to player inventory, preserving tiers and keeping the highest-tier units in the kit. Equal-tier ordering can use the existing deterministic guard-kit order; it does not alter ordinary kit behaviour.
- After a fought defence or an unattended guard-kit repel, refill the recipes actually spent from the highest tiers available in player inventory, up to capacity. Never fill unassigned spare capacity automatically. When a defence spends personal units and guard-kit units, settle personal refill first (player, then recruited allies), then guard kit. Unused kit stock remains with the property.
- Retain faction raider kits as a shared squad pool. For a fought raid or stockpile defence, cap the pool at two units times every raider in the full roster, not only the first three active. Respect the faction's authored kit recipe quantities and actual held tier buckets. Select highest-tier eligible units first; choose randomly among equal-tier candidates using the game's seeded RNG. Each used unit applies its actual tier's effect power and becomes unavailable from faction stock to later fights immediately, even before the daily stock update. Unused units remain stock. Existing non-fought faction raid-kit accounting stays unless required to prevent double spending.

### Dials

- Profile edits personal items and any owned Dial for the player and combat-capable recruited contacts. HQ and Profile open one shared Dial loadout menu; the pre-fight route opens Profile focused on current participants. Seating/unseating crafted Movements and loading/unloading crafted Complications transfer real units to/from the shared player inventory. Winding is available from the shared menu and retains its existing cost and no-time-block rule. Recruits without a Dial show no Dial loadout until granted one.
- On James's recruitment, grant him a level 2 Dial with a tier 1 Recharge Movement seated and tier 3 Time Pearl and Healing Burst loaded. Charge starts full. His former fixed Rewind does not become an item or loaded Complication. Existing saves where James is already recruited gain this state through migration, without duplicating existing player stock. Archie gets no Dial in this feature, but the same editor supports a later grant.
- Ally Dials use the player's Dial mechanics for charge, daily regen, winding, Movement effects, capacity and cast XP/level progression, replacing James's fixed three-casts-per-day rule. On an ally turn, eligible loaded Complications use the same triggers and targeting as equipped items, before personal items. Reactive effects keep their existing trigger timing. Only the player's seated Movement contributes to the player's out-of-combat attunement bonuses.
- Every loaded Complication cast, in combat or an event, uses its owner Dial level. For numeric magnitudes such as damage, healing and shield absorption, multiplier = `1 + 0.25 × level` (levels 1–5: 1.25, 1.5, 1.75, 2, 2.25). Combine it multiplicatively with Impact's existing Movement bonus and round once at the end with the established integer-rounding rule. Fixed-effect semantics remain fixed.
- Time Pearl freeze duration and Prophet's Breath evade duration use their existing base/Movement result plus one turn per Dial level **instead of** the percentage multiplier. Add the Dial-level duration once per cast after Spread's existing target effect.
- Black Hole's attack damage uses the percentage multiplier. Its base freeze duration continues to derive from item power and existing Movement effects without feeding the Dial-level damage multiplier into that derivation. Add one freeze turn at Dial level 3 and another at level 5 (maximum bonus +2), once per cast after Spread.
- Enhancement Powder applies the percentage multiplier to its numeric power before its existing extra-turn thresholds; no separate duration bonus. Other effects retain their established targeting, side effects, charge cost and turn cost unless explicitly changed here.

### Preparation and presentation

- Every combat entry path—offensive vein and stockpile raids, vein/HQ defences, muggings, tutorial/story/event and debug fights—passes through one preparation state before the first combat turn. Planned actions show preparation before travel/time costs, raid rolls and encounter commitment. Fight commits those costs and rolls. Forced/scripted triggers may already be committed; their preparation screen offers no cancel/retreat route. Flee remains an in-combat command.
- Planned raids and defences let the player select and order any currently eligible recruited fighters. HQ defence now permits recruits. Selected recruits take precedence over automatic partner helpers, then hired guards. All selected and automatic fighters beyond the two friendly places beside the player enter the reinforcement queue. Surprise/scripted encounters keep their established participant roster and do not let the player summon recruits who were not present.
- Preparation shows participants and equipped units; when a participating player/recruit has an empty slot and eligible unequipped stock exists, a warning names that character and offers Change loadout. The action opens Profile focused on the participants, then returns to the same pending encounter with the updated view. It edits personal items and Dials, not vein/HQ guard kits.
- Combat command dock replaces the generic Item action with two always-visible item rows. Filled rows show icon, name and tier; unavailable/empty rows remain visible and disabled. Player item use still obeys selection, effect eligibility, playback lock and one-player-occurrence cost, except existing reactive effects such as Rewind/Failsafe retain their established timing. The Bag is read-only while combat is active.
- Give all 14 crafted consumables a distinct small pixel-art item illustration; use the icons wherever those items appear, including combat, Profile, Bag, Dial Complications, events and trade. Replace their text glyphs as item icons; do not redesign Dial Movement symbols. Follow the existing physical-art versus vector-chrome distinction and existing mobile contrast/tap-size rules.

### Reinforcements and outcomes

- Each side has at most three active combatants. The player counts toward the friendly three and starts active. Preserve full encounter rosters instead of clamping raid guard or raider generation to three; muggings keep their existing rolled size. Friendly reinforcement order is the player's pre-fight recruit order, then partner helpers, then hired guards. Enemy reinforcements preserve generated roster order.
- A queued combatant is present in pure game state but does not act, take damage, receive new active-only status effects, or appear as a target/turn-order occurrence before entry. AoE and freeze affect only combatants active when applied. A later entrant does not inherit an earlier freeze. Victory requires all active and queued enemies to be defeated.
- On an active fighter's KO, remove them from active play and admit the first same-side reinforcement immediately into that side's open place. They can be targeted immediately. If the KO'd fighter had an unresolved occurrence in the current round, replace it with one occurrence for the entrant, placed among the remaining occurrences by their own speed and existing tie-break rules. If that fighter already acted, the entrant first acts next round. Existing Motion extra occurrences and Rewind snapshots must not create duplicate or lost turns on substitution. The turn-order strip projects active occurrences only.
- The stage shows up to three waiting fighters per side as much smaller, more distant sprites in queue order, followed by `+N` for additional waiting fighters. A joining fighter leaves the background queue and takes the active place; the displayed count and projected turns refresh without changing player selection unexpectedly. Keep active fighters legible at the 390 × 844 portrait viewport.
- Player KO occurs only after existing automatic Failsafe/Rewind checks. If it stands, remove the player from combat, admit the next friendly reinforcement, and let allies resolve their turns automatically with no player commands. Healing Burst cannot bring the KO'd player back during that fight. Allies defeating all enemies still produce the normal victory, reward and raid outcome. Once the encounter settles, set the player's HP to 10% of hpMax after either an ally-won victory or a loss. If no friendly active or queued fighters can continue after player KO, resolve a loss. Existing recruited-ally KO cooldown rules remain.
- Save/load, autosave, snapshots, Rewind, target selection and turn-order projection must round-trip an active fight, pending preparation state, active/queued roster and equipped/used resource ledger without duplication. Rewind restores the encounter's roster and turn cursor consistently with existing rewind scope while preserving spent resources and existing ally-KO persistence.

## Testing Decisions

- Prefer the highest existing headless seam: initialise real game state, call public preparation/loadout/combat/settlement actions, then assert player-visible state and outcomes. Test behaviour and resource conservation, not private helper calls or exact node structure. Use seeded RNG for tier ties, initiative, target choices and raid outcomes.
- Extend the existing combat, Dial, guard-kit, faction-simulation, raiding, contacts, save/load and event tests at their public seams. Cover transfers among inventory/personal slots/guard kits/loaded Complications, duplicate recipes, tier-0 conversion, full/partial/no refill, refill priority, faction stock depletion, actual-tier power, item-trigger order and no Bag bypass.
- Cover all entry paths through preparation: planned actions before cost/roll, forced encounter after commitment with no cancellation, recruit selection/reordering, current participant warning, Profile/HQ shared Dial editor, return to the same pending encounter, and unchanged surprise-party composition.
- Cover Dial level 1–5 multipliers, one-round rounding, Impact/Spread composition, Time Pearl and Prophet's Breath duration rules, Black Hole level-3/5 freeze breakpoints, Enhancement Powder thresholds, James grant/migration and full-charge start, and event casts.
- Cover reinforcement waves on both sides: more than three enemies/allies, simultaneous KO/entry, unresolved-versus-spent occurrence, entrant targetability, active-only AoE/freeze, Motion extra turns, selection clamp, Rewind, enemy exhaustion, player KO/ally victory and 10% post-fight HP.
- Use the existing headless scene-test pattern for Profile, combat command dock, combat stage and turn-order strip to verify two visible item rows, disabled empty rows, participant focus, icon binding and up-to-three distant reserve sprites with `+N`. Human on-device QA checks icon legibility, background depth, sprite replacement, queue readability and touch targets; headless tests cannot establish visual quality.
- Run all affected Godot 4.7 syntax checks and the full headless suite when implementation tickets land. The spec itself changes no GDScript.

## Out of Scope

- Implementing this spec or creating its action tickets in this invocation.
- Giving Archie a Dial now, or making noncombat recruits fight.
- Player control of ally turns, mid-combat equipment changes, or refilling any combat item during a fight.
- Editing guard kits from Profile or the pre-fight Change loadout action; their existing property controls remain.
- Changing enemy authored weapon bonuses, faction non-fight combat simulation, recipe discovery/crafting formulas, or noncombat item effects beyond tier-0 normalization and the agreed Dial cast scaling.
- Adding a new way to cancel a forced encounter or escape before combat.
- Compensating damage for removed player weapons without a separately approved balance change.

## Further Notes

- This spec supersedes conflicting current combat, kit, player-weapon and ally-Dial rules in `docs/REFERENCE.md` §1.4, §1.6, §2, §3.5, §3.7, §3.7a and §3.9 once the canonical reference is updated. Ticket work must update that reference before implementing changed formulas or schemas; the HTML prototype remains prose-only.
- The current implementation does **not** cap raider kit size per enemy; HQ currently allows three units per guard. Both need explicit change. Existing player consumables currently use crafting skill rather than stored tier. Existing save validation uses a fixed version and backfills selected keys, so migration must keep previously supported saves readable while converting tier 0, weapon state, James's Dial and new loadout fields.
- Preserve the one-way data flow: JSON content; pure serialisable state; systems own state changes and signal emission; screens render and call systems. Maintain the file ownership map with any implementation that adds, removes or repurposes mapped files.
- All new player-facing warning and notification prose needs a `PROSE-REVIEW:` flag in implementation reports. Combat balance requires a check after removal of the crowbar bonus and after full guard waves are enabled; do not hide tuning changes inside implementation.
