# Authoring and inventory pass

Status: ready-for-agent

Five connected workstreams: Storyboard event authoring, recipe buying, the Bag and stash, Root Feed AI, and the ToDo app.

## Problem Statement

**Authoring.** The Storyboard tool can write event prose, checks and conditions, but most effects are read-only. To make a choice or roll raid a vein, claim it, change guard numbers or start a tailored fight, the human has to ask for hand-edited event JSON. The security condition exists in the game but cannot be picked in the tool, so options cannot easily appear only when a vein has a ward, an alarm or a given number of guards.

**Recipes.** Buying from Wren and James shows a long list with every rung. It does not say what an item does, there is no way to narrow it by ore, and owned rungs do not read as clearly owned.

**Bag.** The Bag is a flat read-out. It cannot be filtered or collapsed, hides what items do, and most Use actions sit in a separate block rather than on the item.

**Stash.** The personal stash protects stock from staff, contracts and raids, but it also locks the player out: stashed units cannot be used from the Bag or in events. Protecting stock therefore makes it less useful to its owner, and the UI does not make the split clear.

**Root Feed.** Only the player can apply Root Feed, by hand. Cultivators ignore it. Faction veins cannot run boosts at all, and the Collective's Root Feed is deleted by an abstract weekly `consumes` burn with no effect on the world.

**ToDo.** The ToDo app is a stack of collapsible text sections. It feels clunky, gives each questline no identity, and does not show at a glance what matters in each one.

## Solution

**Authoring.** Storyboard options and outcomes gain dropdown-driven effects for raiding a vein, claiming a vein, adjusting guards for the event, and a mid-event fight with chosen enemies and kit. Security conditions become selectable. The game supports all of this in any event with a site, and fights in any event.

**Recipes.** A seller shows one collapsed row per recipe, with a one-line effect sentence. Tapping expands the rungs and tapping again collapses them. Known rungs show a tick badge instead of a button. An ore filter sits at the top.

**Bag.** The Bag has ore filters and collapsible ore categories. Each row has image, name and `?` on the left, and quantity and Use on the right. Vein items can be used from the Bag through a vein picker.

**Stash.** Anything the player does by hand can draw on the stash, while automated systems never can. Shared stock is spent first. Selling and guard-kit stocking stay shared-only, so a tap cannot sell the reserve by accident.

**Root Feed.** Player cultivators apply it automatically from the shared pool, with an on/off toggle per station. Factions use it too, buying from the Collective or from the player, and it raises their real ore output through normal pruning.

**ToDo.** The app becomes a carousel of questline pages. Each has a large banner and arrows and can be swiped, with that questline's goals underneath.

## User Stories

### Storyboard authoring

1. As an event author, I want to add a "Raid vein" effect to an option or roll outcome, so that a choice can take ore from the event's vein and give it to the player.
2. As an event author, I want to set how much a raid takes per option, so that a greedy choice can take more than a careful one.
3. As an event author, I want a raid to reduce the vein's growth, so that raiding visibly costs the owner.
4. As an event author, I want to add a "Claim vein" effect to an option or roll outcome, so that ownership passes to the player.
5. As an event author, I want to add, remove and edit these effects on success and fail outcomes as well as plain options, so that rolls can change the world.
6. As an event author, I want a dropdown to raise or lower guards for this event, so that choices and rolls can change the fight ahead.
7. As an event author, I want guard changes to last only for the event, so that an event can never quietly alter the vein's real security.
8. As an event author, I want to add a fight to any card outcome, so that fights are not limited to vein raids.
9. As an event author, I want to pick each enemy group's type, number and level from dropdowns, so that I do not write stat blocks by hand.
10. As an event author, I want to choose from enemy templates and faction squads, so that fights use the game's real enemies.
11. As an event author at a vein or stockpile, I want a toggle for enemies to use its real guard kit, so that the fight matches what the place holds.
12. As an event author, I want to give enemies their own shared loadout for one fight, so that a story fight can be tailored.
13. As an event author, I want the guard kit toggle hidden when the event has no vein or stockpile, so that I cannot author an impossible fight.
14. As an event author, I want to choose where a win and a loss go, so that the fight sits inside the event flow.
15. As an event author, I want an option to appear only if the event's vein has a ward, so that the choice fits the place.
16. As an event author, I want an option to depend on an alarm, cameras or locks, so that any security feature can gate a choice.
17. As an event author, I want an option to depend on at least or at most a number of guards, so that scale changes the options.
18. As an event author, I want to gate on a feature being absent, so that "no ward here" choices are possible.
19. As an event author, I want to choose hide or disable for a gated option as I can today, so that security gates behave like other requires.
20. As an event author, I want the tool to warn me when a site effect or condition sits on an event with no site, so that I catch dead options before promotion.
21. As an event author, I want unknown effects to stay read-only and pass through untouched, so that the editor never damages existing events.
22. As an event author, I want new fields to survive a save, reload and promotion, so that what I authored is what ships.
23. As a player, I want raid, claim and guard outcomes to apply exactly as the card reads, so that my choices feel real.

### Recipe buying

24. As a player, I want one row per recipe at Wren and James, so that I can scan what is on offer.
25. As a player, I want a short sentence on each row saying what the item does, so that I can decide without leaving the screen.
26. As a player, I want to tap a recipe to expand its rungs, so that the list stays short until I care.
27. As a player, I want to tap again to collapse it, so that I can tidy the list as I go.
28. As a player, I want a known rung to show a tick badge instead of a buy button, so that I cannot mistake what I own.
29. As a player, I want an ore filter at the top, so that I can narrow the list to the ore I work with.
30. As a player buying from James, I want the filter to offer only ores James teaches, so that no filter leads to an empty list.
31. As a player, I want the basket, review and pay flow unchanged, so that I can still buy several rungs at once.
32. As a player, I want locked rungs to keep their reason, so that I know what to do next.

### Bag

33. As a player, I want ore filters at the top of the Bag, so that I can find items quickly.
34. As a player, I want each ore category row to collapse and expand, so that I can hide what I do not need.
35. As a player, I want each row to show image, name and `?` on the left, so that every item reads the same way.
36. As a player, I want `?` to open a modal with effect and description text, so that the list stays clean.
37. As a player, I want quantity and a Use button on the right, so that I can act from the row.
38. As a player, I want Use shown only where an item can be used now, so that a button always does something.
39. As a player, I want one row per item with a tier picker on Use, so that tiers do not clutter the list.
40. As a player, I want to see my raw ore in a row at the top, so that I keep the overview I have today.
41. As a player, I want the Dial summary kept, so that I lose no information.
42. As a player, I want to use Root Feed, Good Year and Deadweight from the Bag through a target picker, so that I need not find the vein first.
43. As a player in combat, I want filters and `?` with no Use buttons, so that the Bag stays a read-only reference there.
44. As a developer, I want new item art found automatically from its file name, so that adding art needs no wiring.

### Stash

45. As a player, I want the two pools labelled Shared and Stash everywhere, so that I know what staff can touch.
46. As a player, I want to use stashed items from the Bag, so that protecting stock does not lock me out of it.
47. As a player, I want events to count and spend stashed items and ore, so that my reserve helps me in a story moment.
48. As a player, I want loadout equip and hand-crafting at the Lab to draw on the stash, so that everything I do myself can reach my reserve.
49. As a player, I want shared stock spent before stash, so that my reserve lasts longest.
50. As a player, I want a small "in stash" line on a Bag row, so that I can see the split without visiting HQ.
51. As a player, I want the total to include stashed units, so that the number is what I really hold.
52. As a player, I want selling and guard-kit stocking to stay shared-only, so that one tap cannot spend my reserve.
53. As a player, I want staff, contracts, Sales, Production and raids never to touch the stash, so that it is a real guarantee.
54. As a player, I want stash moves to stay on the HQ ore slip, so that moving stock stays deliberate.

### Root Feed

55. As a player, I want my cultivators to apply Root Feed when a vein needs it, so that I do not have to micromanage boosts.
56. As a player, I want an on/off toggle per station, so that I decide where feed goes.
57. As a player, I want cultivators to use only the shared pool, so that stashing is how I reserve feed.
58. As a player, I want cultivators to use the lowest tier first, so that my better stock is kept.
59. As a player, I want them to skip a vein already being fed, so that no feed is wasted.
60. As a player, I want applying feed not to cost the cultivator's action, so that the vein still gets tended.
61. As a player, I want a visible record when a cultivator uses feed, so that stock drops are explained.
62. As the Collective, I want to apply my own Root Feed to my lowest-growth vein, so that it is used rather than deleted.
63. As another faction, I want to buy Root Feed from the Collective's for-sale stock, so that the item reaches the rest of London.
64. As a player who makes Root Feed, I want factions to buy it from me through normal sales routes, so that it is a real product.
65. As a player, I want factions at war with the Collective unable to buy from it, so that the economy respects the conflict.
66. As a player, I want a faction's Root Feed to raise its real ore output, so that the item matters in the simulation.

### ToDo

67. As a player, I want a page per questline with a large banner, so that each one has an identity.
68. As a player, I want to swipe the banner or tap arrows to change page, so that moving between questlines feels natural.
69. As a player, I want dots showing where I am and a pip for a new goal, so that I can see what changed.
70. As a player, I want the app to open on the most recently changed questline, so that it starts on what matters.
71. As a player, I want active goals first with their checklists and counts, so that the next step is obvious.
72. As a player, I want done goals collapsed and dimmed, so that progress is kept without clutter.
73. As a player, I want no "n of N" total for a questline, so that the count does not spoil what is coming.
74. As a player, I want the rent and deposit goal in a slim pinned strip, so that money pressure is always visible.
75. As a player, I want the Collective's site ledger to stay available and collapsible, so that I keep that information.
76. As a player, I want a Board page showing base, target and stretch steps, so that the board goal reads as a ladder.
77. As a player, I want a locked banner for an unstarted questline with its empty text, so that it reads as ahead of me.
78. As a player, I want finished questlines stamped, desaturated and moved last, so that the live ones come first.
79. As a developer, I want banner art found by questline name, so that replacing crops with final art needs no wiring.

## Implementation Decisions

### Storyboard tool

- New controls live in the Storyboard only, outside the section it shares with the mobile quest editor. That shared section stays byte-identical and the sync test stays green. The mobile editor gets no new UI and must pass the new fields through unchanged.
- The effect editor gains an "Add effect" dropdown on plain options, on success and fail outcomes, and on any other per-outcome effects list the tool edits. Choices are Raid vein, Claim vein, Adjust guards and Fight. Other effects stay read-only.
- Security conditions are added to the Storyboard's condition picker, for `requires` and `hideUnless`. Controls are feature (ward, guards, alarm, cameras, locks), then present, absent, at least or at most with a number where relevant. They write the existing `{security}` condition, using `atMost: 0` for absent.
- Enemy and kit dropdowns extend the catalogue the Storyboard already installs for items.
- The tool warns on site-dependent effects or conditions when an event has no site or vein, and on "use guard kit" when there is no vein or stockpile.
- The event promotion script passes every new field through.

### Event runtime

- **Site scope.** Raid, claim, guard and security features work in any event with a site in its context, not just raid events.
- **Security profile.** When an event with a site has no `securityProfile` in context, the game builds one from that site's vein. This covers faction and player veins. A site with no vein reads as no security.
- **Live guards.** Security conditions read the guard count after this event's adjustments.
- **Raid.** `loot_raid_vein` gains an optional depth. It lowers the vein's growth by that depth, floored at 0, and pays ore through the existing prune-yield formula. With no depth, it uses a new data constant tuned so expected ore is close to today's fixed amount. Existing events therefore keep working and now drain the vein. Other consequences stay as they are.
- **Claim.** `claim_raid_vein` keeps today's meaning and transfers to the player only. Claiming for another faction is out of scope.
- **Guards.** Guard adjustment becomes signed and event-scoped. A positive value adds guards and a negative value removes them, through the existing event context count. It never edits the vein. Existing `reduce_raid_guards` uses keep their behaviour.
- **Fight op.** A new effect op starts a data-driven fight in any event and is added to `VALID_EFFECT_OPS`.
  - **Enemies:** a list of groups, each a template or faction squad plus count and level. Stat blocks stay exclusive to `start_scripted_fight`.
  - **Vein guards:** a group may size itself from the vein, as `guards: "vein"` does today, including this event's guard adjustment.
  - **Kit modes:** `none`, `guardKit` (real kit at the vein or stockpile) or `custom` (one shared authored kit of items and tiers). Per-enemy loadouts are not supported.
  - **Kit spending:** `guardKit` spends the real kit under existing raid settlement rules. `custom` is free and touches no stock.
  - **Reinforcements:** the op accepts existing alert-driven waves and `situational` mods where they apply.
  - **Flow:** win and lose name destination cards. Fleeing uses the lose route. Entry goes through the Preparation sheet as a forced combat, and allies follow current event fight rules.
- REFERENCE.md §3.9a, §3.7b and the event action list are updated in the same work.

### Recipe buying

- The seller's recipe view becomes collapsible recipe rows over the existing rung data. Rung, basket, review and refusal logic stay where they are.
- Rows show the recipe name, its icon and `effectText`. Expanded rows show each rung. A known rung shows a tick badge. A locked rung shows its current reason.
- The filter has All plus only the ores that seller teaches, using the same ore grouping as the Lab recipe book.
- Expanded rows and the filter are local view state, not game state.
- Every recipe gets `effectText`, a plain statement of what it does. The current gap is 35 of 43. This is new prose under CONTENT-GUIDE.md and is flagged `PROSE-REVIEW`.

### Bag

- A pure projection returns filter options, categories and rows, so the drawer only renders it. Rows carry the item key, quantity total, stash quantity, usability and use action.
- Layout order: raw ore row, ore filter, collapsible ore categories, active effect lines, Dial summary, Close.
- Only held items are listed. Empty categories are hidden.
- Items use the Lab grouping for multi-ore recipes, and multi-target variants keep their own row.
- `?` opens a modal with name, `effectText` and `description`.
- Use appears only when the action is available in management mode. Combat has filters and `?` but no Use, and no loadout changes.
- Use shows a tier picker when more than one tier is held. Target items use a picker: veins for boosts and vein Deadweight, plus HQ for Deadweight, contacts for Smelling Salts, and grudges for Clean Slate. All of this calls the existing apply functions (ADR 0007).

### Art asset contract

- Item icons resolve `assets/items/<recipeKey>.png` first, then the recipe's `icon`, then the symbol. No data edit is needed when art lands. This follows the asset contract pattern in ADRs 0003 and 0005.
- ToDo banners resolve `assets/phone/todo/<questline>.png` with a default fallback. Crops of existing event art ship at those paths for now.

### Stash

- A single player spend seam handles checking, counting and spending across shared then stash, for both ore and items, preserving tiers. Lowest-tier-first rules stay per caller.
- **May use the seam:** Bag use, player-applied vein items, event requirements, mods, item offers and costs, loadout equip, and hand-crafting at the Lab.
- **Shared only:** contracts, Sales, Production, Procurement, cultivators, manual selling and gifting, and guard-kit stocking. Raids stay unable to reach the stash.
- Player-facing labels become Shared and Stash. Moves stay on the HQ ore slip only.
- REFERENCE.md's stash and Lab sections are updated. The stash remains the only reserve mechanism, so no per-item reserve number is added.

### Root Feed

- **Player.** The cultivator step checks Root Feed before prune or cultivate, on the vein it is working. It applies one unit at the lowest tier held when the station toggle is on, growth is below the station target, Root Feed is not already running and the shared pool holds some. Applying costs no action.
- **Toggle.** A per-station boolean is saved in game state, backfilled on load, and defaults on. It appears wherever the player sets a station's target.
- **Record.** Use appears in the production or station log, or the nearest existing staff report.
- **Boosts on faction veins.** The daily tick runs boosts on faction veins too, after drift, with the same rates and ceiling. Boosts stored on a vein follow it on transfer. Only Root Feed use is added for faction AI, not Good Year or Deadweight.
- **Faction output.** Faction veins gain growth, and existing fieldwork pruning turns growth above `pruneFloor` into holdings. No separate output multiplier is added.
- **Faction use.** Each faction holding Root Feed applies one to its lowest-growth unfed vein, in a daily step, up to a data-driven limit.
- **Collective.** The `consumes` entry is replaced by real use. `kitUse` takes over the same amount, so its craft target stays unchanged.
- **Buying from the Collective.** A daily step lets other factions buy from Collective for-sale stock at market quote, paying from their resources. It is blocked while at war with the Collective.
- **Buying from the player.** Once the player owns the base recipe rung, Root Feed joins other factions' demand in sell lanes and sales offers. Stock comes from the shared pool only and enters real holdings. These factions get no `consumes` entry for it, so nothing is burned abstractly.
- All new quantities and limits are data-driven placeholders for balance. REFERENCE.md §1.8, §3.4 and the daily order are updated.

### ToDo

- `Todo` gains a page projection: one page per questline in display order, then Board. Pages carry label, subtitle, accent, status, new-goal pip, active goals, done goals, ledger, empty text and Board ladder steps.
- Questline presentation moves to data. This includes label, subtitle, accent colour and done flag.
- `MAX_ITEMS_PER_SECTION` is removed, as done goals now collapse.
- A new saved `todo` state records seen and last-changed marks per questline, backfilled on load. The app marks a page seen through a system call. No Node state enters the game state.
- The app uses Family 2 phone chrome. The banner takes about 35% of height. Swipe works on the banner only, so vertical scrolling of goals is not disturbed. Arrows hide at each end, and the carousel does not wrap.
- Page order puts started questlines first, unstarted placeholders next and finished last. Board sits after live questlines.
- The rent and deposit strip stays pinned above the banner.
- Goals remain read-only. Tapping a goal does nothing.

## Testing Decisions

Good tests assert outcomes a player or author sees through a public seam, such as stock, growth, ownership, routing and projected rows. They do not assert private helpers or layout details. Set state directly and cap any loop, as the project's test hygiene rules require.

- **Storyboard:** `tools/test_storyboard.js` covers lossless round trips of every new field, warnings, and pass-through of unknown effects. `tools/test_quest_editor.js` must stay green with the shared section unchanged. A promotion test confirms fields survive.
- **Event runtime:** run `Events` effects and `condition_met` at the public seam for loot depth and growth drain, default loot, claim, signed guards, and security conditions on faction veins, player veins, and sites with no vein. Fight tests cover start and resume in vein and non-vein events, all three kit modes, real kit spending, and win, lose and flee routing. Prior art: `tests/test_events.gd`, raid event tests.
- **Data:** every recipe has `effectText`, and every new op is valid. Prior art: existing data validation tests.
- **Stash:** one test per caller group proves shared-then-stash spending, tier preservation and correct totals. Automated systems must leave the stash untouched, including when shared stock is empty. Prior art: `tests/test_stash.gd`.
- **Root Feed:** block-step tests cover each cultivator rule and action count, through `Rooms`. Prior art: `tests/test_rooms.gd`, `tests/test_cultivating.gd`.
- **Factions:** daily-tick tests through `FactionSim` cover boost ticks, buying, the war block, the stock limit, and resources paid. The required acceptance test is that, over N days, a fed faction vein produces more ore than an identical unfed one. Prior art: `tests/test_faction_sim.gd`.
- **UI projections:** pure tests with no Nodes cover Bag rows and filters, recipe rows and seller filters, and ToDo pages, ordering, pips and page choice. Prior art: `tests/test_bag.gd`, `tests/test_bag_drawer.gd`, `tests/test_recipe_knowledge.gd`, `tests/test_todo.gd`.
- **Art lookup:** the convention path wins, and fallbacks work. Prior art: `tests/test_item_icons.gd`.
- **Save:** old saves load with new `todo` and station toggle keys backfilled.
- **Manual QA:** swipe feel, banner layout, collapses, modals and the Storyboard UI are checked by the human.

## Out of Scope

- Claiming a vein for another faction, in events.
- New UI in the mobile quest editor, beyond keeping its sync test and pass-through intact.
- Per-enemy item loadouts and hand-written enemy stat blocks in the new fight op.
- Permanent guard changes from events.
- Final item icons and final ToDo banners. These are art tickets.
- Moving stock between pools from the Bag.
- Tapping a ToDo goal to jump to a screen.
- Faction AI use of Good Year or Deadweight.
- Stash access for selling or guard-kit stocking.
- Writing new events that use these tools.
- Final balance of raid depth, Root Feed demand and faction limits.

## Further Notes

- Prose: all new `effectText`, UI strings and notifications carry `PROSE-REVIEW`. Follow CONTENT-GUIDE.md, and keep to vein cultivation language, with no gardening vocabulary.
- Suggested order: art asset contract and `effectText` first, then stash seam before the Bag. Faction boost ticks come before faction buying. The fight op comes before its Storyboard controls. ToDo is independent.
- `CODEMAP.md` needs updating for any file whose responsibility changes.
- The default loot change alters existing raid events: the four current `loot_raid_vein` uses now drain vein growth. This was approved.
