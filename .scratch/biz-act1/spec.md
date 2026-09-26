# PRD — Business Empire, Act 1

**Status:** ready-for-agent

**Source:** `docs/biz-act1-vision.md` plus the design Q&A of 2026-09-25. Every
decision below was put to the human and confirmed. Where this document and the
vision disagree, **this document wins** (the vision's weekly-only accounting,
"no wage debt", James-joins-at-Beat-5 share timing, and the separate Owen
chooser were all superseded in Q&A).

**Scope of authority:** canonical for the mechanics it defines. Where it
conflicts with `docs/REFERENCE.md` (§2 contacts/sales schema, §3.10 contacts,
rooms, jobs) or the completed business spec
(`.scratch/COMPLETED/day-rhythm-business-and-combat_COMPLETED/business-spec.md`),
this document wins and the conflicting REFERENCE.md section is amended in the
same ticket that lands the conflicting code.

**Written on top of:** the live BizBrief (Brief + Manage tabs), `Offers`,
`Contracts`, `Payroll`, `Rooms` (Lab / Vein Station), `Contacts`, `Objectives`,
`Todo`, `Messages`, the event runner, and Collective Acts 1–2. All reused, not
rebuilt.

## Problem Statement

Once the player holds a second vein, the game has no reason
for the player to think bigger than their own hands. Every unit of calc is
cultivated, harvested, crafted, and delivered by the player personally, three
time blocks a day. BizBrief exists, but its staff roles are locked behind
late-game rooms (Operations Room at a safehouse, Improved Lab at a compound),
so a mid-game player never sees delegation work. Archie and James are
recruitable only by grinding relation, which says nothing about why they would
go into business together. There is no questline in the ToDo app's "Business
Empire" section — it reads "Nothing on the books yet."

## Solution

A seven-beat questline, independent of and able to run alongside the Collective questline, that turns
the player's veins into a small three-person business:

- **Archie** handles sales: he sources BizBrief offers and delivers delegated
  contracts.
- **Owen**, a young Guild cultivation apprentice James quietly arranges, tends
  the player's veins one action per time block.
- **James**, after the player proves the market and the supply, crafts for the
  business one attempt per time block.

The player chooses veins, contracts, assignments, and spending. Once Owen is
hired, contract income flows into a **business pot**; every payday (every
seventh day) the pot pays business expenses — Owen's £250 weekly wage and any
calc Archie bought for orders — and the remainder is split evenly between the
player, Archie, and James. The act ends when two recurring contracts have each
completed a full period with no help from the player.

The three founders (Archie, James, Owen) can be assigned to a role without any
room. Future hires still need the matching room.

## User Stories

### Starting the act

1. As a player who owns two veins, I want Archie to text me with a proposition, so that the business questline starts at a natural moment.
2. As a player, I want the proposition to trigger as soon as I hold two veins, whatever my Collective progress, so that I am not made to wait for an arbitrary day.
3. As a player, I want a story scene where Archie takes me to James and pitches a three-way business, so that the partnership has a reason to exist.
4. As a player, I want James to set conditions (proof of a reliable market and a serious investment) rather than agree at once, so that the partnership feels earned.
5. As a player playing the Collective questline at the same time, I want the business beats to run alongside Act 2 without blocking it or being blocked by it, so that I can progress both.

### Market proof (Beat 2)

6. As a player, I want Archie to introduce BizBrief offers and contracts, so that I understand how orders work.
7. As a new player, I want Archie to hand me a reliable starter offer, so that random offer rolls cannot strand me.
8. As a player, I want each starter offer to arrive one day after the previous one closes, so that I am fed a steady but not overwhelming supply.
9. As a player who lets a starter offer expire or declines it, I want Archie to reissue it after a day, so that the quest cannot soft-lock.
10. As a player who already completed BizBrief contracts before the pitch, I want those completions to count toward the three, so that I am not made to repeat work.
11. As a player, I want only fully completed contracts to count toward James's test, so that late partial deliveries do not look like reliability.
12. As a player, I want the ToDo app's Business Empire section to show my progress toward three completed contracts, so that I know what is left.
13. As a player, I want the proceeds of contracts completed before Owen joins to be paid straight to me, so that pre-business work stays mine.

### Owen (Beats 3–4)

14. As a player who has completed three contracts, I want a story scene where James introduces Owen, so that I meet my first worker as a person, not a hire button.
15. As a player, I want Owen to appear in my Contacts, so that he is part of the same world as everyone else.
16. As a player, I want BizBrief to gain a Staff tab when Owen arrives, so that I can see and assign my people.
17. As a player, I want to assign Owen to cultivation and pick which veins he tends in Manage → Procurement, so that he works where I need him.
18. As a player, I want Owen to act once at the end of every time block (Morning, Afternoon, Evening), so that his work feels like it happens alongside mine.
19. As a player who rests or ends the day early, I want Owen still to take his actions for the skipped blocks, so that a day always gives him three actions.
20. As a player, I want Owen to use the same cultivator rules as any hired cultivator (hold each vein near its target, prune if above, cultivate if below), so that there is one system to learn.
21. As a player with many veins, I want one cultivator able to tend any number of veins, picking the one furthest from its target each block, so that throughput (one action per block), not a cap, limits how many they can keep up with.
22. As a player, I want Owen to sit idle when all his veins are near their targets, so that he does not waste growth.
23. As a player, I want Owen's harvest to land in my shared stock, so that the business can use it.
24. As a player, I want Owen to gain experience slowly (2 XP per action) and reach cultivating level 2 over roughly two weeks, so that his progress feels like an apprentice's.
25. As a player, I want Owen's skill capped at level 3 for cultivating and crafting, so that his limits match James's assessment of him.
26. As a player, I want the Beat 4 goal to be "Owen cultivating level 2 and a Workshop in your home", so that I know what James is waiting for.
27. As a player who already built a Workshop, I want it to count immediately, so that I am not made to rebuild.
28. As a player, I want the ToDo app to show Owen's level and the Workshop as checklist items, so that I can track both.

### The business pot and payday

29. As a player, I want contract payments to go into a business pot from the day Owen joins, so that business money is separate from my own.
30. As a player, I want Archie and James each to take a third of the business proceeds from Owen's hire onward, with James as a limited partner until he joins fully, so that the partnership is fair from the start.
31. As a player, I want the story to explain that James starts as a limited partner (helping source Owen) and later joins fully to craft, so that his early share makes sense.
32. As a player, I want the story to mention that James keeps his own side business, so that his jobs continuing makes sense.
33. As a player, I want payday every seventh day, so that the business has a steady rhythm.
34. As a player, I want the morning BizBrief after payday to show the week's receipts, expenses, and each person's share, so that I can see where the money went.
35. As a player, I want Owen's wage (£250 a week, prorated for a partial first week) paid out of the pot, so that his cost is a business cost.
36. As a player whose pot cannot cover Owen's wage, I want to be offered the choice to pay him from my own cash, so that I can keep him working.
37. As a player who declines, I want Owen to stop working until he is paid, so that the consequence is clear.
38. As a player, I want an owed wage to be paid in full as soon as the pot or I can cover it, after which Owen resumes, so that he is treated fairly.
39. As a player, I want a "Pay now" button in BizBrief while Owen is owed, so that I can clear it the moment I have cash.
40. As a player, I want my share credited to my cash on payday, with a bank record, so that I can spend it.
41. As a player, I want rounding remainders from the three-way split to go to me, so that no pound disappears.
42. As a player, I want the pot emptied every payday (no retained earnings), so that the accounting stays simple.
43. As a player, I want sales I make outside BizBrief (Archie lane, faction trade) to stay entirely mine, so that the business does not tax my side deals.
44. As a player, I want Archie and James never to draw a daily wage, only their share, so that partners are partners.

### The partnership (Beat 5)

45. As a player who has met Beat 4, I want a story scene where James agrees to join fully, so that the partnership is sealed.
46. As a player, I want James to become a recruited contact through this scene, not through a relation threshold, so that his arrival is a story moment.
47. As a player who somehow already recruited James, I want the scene still to play without breaking anything, so that old saves stay safe.
48. As a player, I want James's crafting skill set to 5 when he joins, so that he is the master crafter the story says he is.
49. As a player, I want to assign James to production from the Staff tab, so that the business can make goods.
50. As a player, I want James to keep crafting at the end of each time block until my Production targets and contract needs are met or he runs out of ore, so that stock is topped up without babysitting.
51. As a player, I want James to use ore from shared stock, never my personal stash, so that my reserve stays mine.

### Archie's sales role

52. As a player, I want Archie assignable to Sales from Beat 2 without an Operations Room, so that I can use BizBrief mid-game.
53. As a player, I want Archie to source at most one new offer per day at rollover, so that offers keep arriving.
54. As a player, I want delegated deliveries to happen instantly whenever stock allows, with no cap, so that nothing sits waiting for a slot.
55. As a player, I want delegation available once Archie teaches it in Beat 6, so that the feature arrives with its lesson.
56. As a player, I want a per-contract switch beside each contract letting Archie buy missing calc from the cheapest source available to me (relation discounts included), paid from the pot, so that a short supply need not fail an order.
57. As a player, I want Archie to buy only the shortfall (the ore still missing, or the ingredient calc James needs for the remaining crafted units), so that the pot is not wasted.
58. As a player, I want Archie to skip a purchase the pot cannot cover rather than dip into my cash, so that my money is safe.
59. As a player, I want those purchases recorded as that week's business expenses, so that the payday statement is honest.

### Put it to work (Beats 6–7)

60. As a player, I want a story scene where Archie demonstrates a recurring order and delegation, so that I learn by doing.
61. As a player, I want a guaranteed weekly Time Pearl order (5 a week), so that at least one order uses James's production.
62. As a player, I want to choose my second recurring order from two reliable weekly ore orders (6 time ore or 6 life ore), so that I have a say.
63. As a player who already has a recurring contract running, I want it to count toward the goal if it is delegated, so that earlier work is recognised.
64. As a player, I want the goal to require each of two recurring contracts to complete one full period with no help from me, so that the proof is real.
65. As a player, I want to know exactly which of my actions count as "help" (handing over goods myself, crafting the requested item, tending one of Owen's veins, moving the requested goods out of my stash, buying the requested calc), so that I can avoid them.
66. As a player, I want everything else (other veins, other crafting, combat, Collective quests) to leave the proof intact, so that I can keep playing.
67. As a player, I want calc Archie buys automatically not to count as help, so that using the business's own tools is not penalised.
68. As a player who accepts an order mid-week, I want the short first period to count if it completes untouched, so that timing is not a trap.
69. As a player, I want the two orders not to need to qualify in the same week, so that one bad week does not reset both.
70. As a player, I want a closing scene where BizBrief shows both completed periods, Owen's wage, and the three-way payout, with Archie excited and James grudgingly approving, so that the act lands.
71. As a player, I want the operation to keep running after the act ends, so that the business is a lasting part of my game.

### Owen learns to craft

72. As a player, I want an event where Owen starts learning to craft once he is cultivating level 2, James has joined, and I own a Workshop, so that he grows as a character.
73. As a player, I want Owen's crafting role to unlock through that event, so that I can move him to production.
74. As a player, I want to swap Owen between cultivation and crafting whenever I like, with no penalty, so that I can put him where I need him.
75. As a player, I want Owen to perform whatever role he holds when each time block ends, so that swapping takes effect immediately.
76. As a player, I want Owen's veins left untended while he crafts, so that the trade-off is visible.

### Staff tab

77. As a player, I want the Staff tab to list every recruited contact with their role, skills, XP, skill caps, and pay terms (share or wage), so that I can see my whole team.
78. As a player, I want the Staff tab to show whether Owen is working or unpaid, so that I spot problems.
79. As a player, I want to change a founder's role from the Staff tab, so that assignment has one home.
80. As a player, I want the Staff tab to link to Manage → Procurement for vein picking, so that I find the vein controls.

### Saves and recruitment

81. As a player whose save is past the home raid, I want Archie treated as recruited on load, so that the act works for me.
82. As a player, I want no relation-based Recruit button for Archie or James, so that their recruitment is a story event.
83. As a player whose Archie or James sits in a room assignment, I want that converted to the equivalent role on load, so that nothing breaks.
84. As a future player hiring someone else, I want hires beyond the founders still to need the matching room, so that facilities still matter.

## Implementation Decisions

### Questline and objectives

- A new questline `business_empire` fills the existing ToDo placeholder. Beats are objectives in the existing objectives catalogue, evaluated by `Objectives.refresh()`, with new evaluator types where needed:
  - **Beat 1 trigger:** the player owns ≥ 2 veins, **independent of the Collective questline**. Collective Act 1 need not be started or finished. Archie must be recruited (true from the home-raid debrief onward), so this is always post-tutorial. Checked after any change in vein count (event completion, seeding, purchase, self-seed) and at rollover as a backstop. Archie queues a text through `Messages.queue_pending`, which leads into a Beat 1 story scene. A permanent flag blocks re-firing. Beat 1 prose must not assume where the second vein came from.
  - **Beat 2:** count of fully completed BizBrief contract settlements (`settlement.complete == true`), read live from `sales.contractHistory`, so completions before the pitch count. Target 3. A completed recurring period counts as one.
  - **Beat 3:** Beat 2 met → James story scene introducing Owen. On completion, Owen is unlocked and recruited, the Staff tab opens, the business pot activates, Archie and James become partners (James as a limited partner), and the recurring ore offers start.
  - **Beat 4:** live checks: Owen `cultivatingSkill ≥ 2` AND `workshop` in `home.rooms`. Both are live state, not counters, so a tier move that wipes the Workshop un-meets the objective.
  - **Beat 5:** Beat 4 met → partnership scene. James is recruited, his `craftingSkill` is set to a data-driven value (5), and the Production role unlocks for him. Recruit side effects are idempotent if he is already recruited.
  - **Beat 6:** a scene in which Archie demonstrates a recurring order and unlocks delegation. It issues the guaranteed Time Pearl recurring offer (the two ore choices already run from Beat 3; an ore contract taken earlier counts once delegated). Objective: two distinct recurring contracts each have at least one qualifying period (see "Unattended proof"), at least one of which requests a crafted item.
  - **Beat 7:** Beat 6 met → closing scene reading the latest payday record. Act complete.
- Story scenes (Beats 1, 3, 5, 6, 7, and Owen's crafting event) are events under the existing event data format. Beats 2 and 4 are ToDo goals plus text nudges. All new prose is drafted against CONTENT-GUIDE.md and CHARACTER-VOICE-GUIDE.md and flagged `PROSE-REVIEW:`. The quest text must say that James keeps his own business on the side (James jobs continue unchanged) and that he joins at Beat 3 as a limited partner who helped source Owen, then fully at Beat 5.
- The hourglass James turns in Beat 1 is an ordinary object. There are no Guild contracts, no Guild invitation, and no Dial reveal.

### Contacts and roles

- **Owen** is a new roster entry in the contacts data: unlocked and recruited only by the Beat 3 event, `recruitable: false` (no relation path), no combat kit (`combatHpMax: 0`).
- **Relation recruitment is removed for Archie and James.** Both become `recruitable: false`. The mechanism stays for any other contact.
- **Archie** is recruited by the home-raid debrief (§3.8). Save fix-up on load: if `homeRaidEventSeen` is true, Archie is set recruited.
- **Per-contact skill caps:** a new optional `skillCaps` map on a contact (Owen: `{cultivating: 3, crafting: 3}`). The contact-XP level-up loop stops at `min(ladder max, cap)`. This is independent of the pending level-10 ladder work.
- **Room-free roles:** contacts gain an `assignedRole` field (`null | "sales" | "cultivation" | "production"`), exclusive with `assignedRoom`: setting one clears the other.
  - Only contacts flagged as founders (`roomFreeRoles: true`: Archie, James, Owen) may hold an `assignedRole` without a room.
  - Future hires can only be assigned by staffing the matching room (Operations Room → Sales, Vein Cultivation Station → Cultivation, Improved Lab → Production). Their room assignment makes them a member of that role.
  - A contact holds exactly one role at a time.
  - Role availability: Archie → Sales from Beat 2. Owen → Cultivation from Beat 3, and Production after his crafting event. James → Production from Beat 5.
  - Load fix-up: a founder with a non-null `assignedRoom` is converted to the matching `assignedRole` and the room assignment cleared.
- Several contacts may share a role (for example Owen and James both in Production).
- **Cultivator ↔ vein assignment:** every cultivator (founder or room-staffed) follows the Vein Cultivation Station logic and has **their own list of assigned veins, with no cap on its length**. The only limit is throughput: one action per time block, so a cultivator with more veins than they can hold in band falls behind. Each vein appears on at most one cultivator's list; assigning it to another cultivator moves it. This replaces the single shared `veinStationVeins` list, which is migrated on load to the Station's current occupant, or to Owen if he is the only cultivator. Per-vein targets stay keyed by vein id.

### One staff system, per time block

- All staffed cultivators and producers act **at the end of every player time block**, whether the contact reached the role by a room or by a founder role.
  - Hook: `TimeSystem.advance_time_block()` runs the staff block step for the block that just ended, before any rollover. `TimeSystem.do_rest()` first runs the staff block step once for each block still remaining that day, then rolls over. A day therefore always yields exactly 3 staff actions per worker.
  - A worker acts only if their wage is paid (for founders, only Owen has a wage).
  - Order within a block: cultivators first, then producers, then Sales' instant delivery re-check (the existing `shared_stock_increased` path).
- **Cultivators** (replaces the once-daily Vein Station pass and removes the separate Owen chooser):
  - Each block, the worker takes the one assigned vein furthest outside its target ±5 band. Per-vein targets are kept, default 70.
  - Above the band → prune down to the target, yield into shared stock. Below the band → one cultivate roll at the worker's skill (existing station semantics). Every vein within its band → idle.
  - Ties go to vein assignment order.
  - XP: **2 per action** (prune or cultivate, success or fail), replacing the station's old 15/20/8 values. This is a data value.
- **Producers:**
  - Each block, producers keep making craft attempts toward the existing Production effective targets (personal target + contract need when "cover contracts" is on) until every target is met or the next item's ore is short, then wait for the next block. Multiple producers take turns one attempt at a time, in role order.
  - The existing priority order applies: contract-card order first, then target order.
  - Uses the worker's crafting skill, shared-stock ore only, and existing XP rules (full or ⅓).
  - Idle if nothing is below target or ore is short.
- **Sales:**
  - Sourcing stays once per day at rollover, using the existing chance formula with the Sales worker's `salesSkill`.
  - Delivery for delegated contracts stays instant whenever stock increases, plus the rollover partial pass, with no cap.
  - `Contracts.has_staffed_sales()` becomes "any contact holds the Sales role". Delegation is additionally gated on a Beat 6 flag.
- **Wages:**
  - Room-staffed hires keep the existing daily formula `£100 + £50 × (skill − 1)`.
  - Founders never draw a daily wage.
  - Owen's wage is the business weekly wage below.
  - `Payroll.pay_wages()` skips founders.
- Because staff work now happens per block, the rollover staff phase keeps only: Sales partial deliveries, due settlements and renewals, the payday step, and offer sourcing. The Morning Brief's stock/production summary aggregates the previous day's block actions.

### Starter and recurring offer catalogue

New scripted templates in the offers data (quote formula unchanged: snapshotted live value × 125%, etc.):

| Template | Type | Request | Notes |
|---|---|---|---|
| `biz_starter_1` | one-off | time ore × 4 | Beat 2 chain |
| `biz_starter_2` | one-off | timePearl × 3 | Beat 2 chain |
| `biz_starter_3` | one-off | life ore × 5 | Beat 2 chain |
| `biz_recurring_time_pearl` | recurring, weekly | timePearl × 5 | Guaranteed at Beat 6 |
| `biz_recurring_time_ore` | recurring, weekly | time ore × 6 | From Beat 3, choice A |
| `biz_recurring_life_ore` | recurring, weekly | life ore × 6 | From Beat 3, choice B |

- **Starter chain:** while Beat 2 is unmet, exactly one starter is outstanding at a time. The next starter (or a reissue of the same one, if it expired or was declined) is created **one day after** the previous starter's offer or contract closes. The chain stops as soon as Beat 2 is met, whatever the source of the completions. Authored expiry and deadline per template.
- **Recurring offers:** the two ore choices are issued from Beat 3 (Owen joins), so the pot has income for Owen's wage before James joins; the Time Pearl order from Beat 6. Before Beat 6 they are ore-only. The player still takes one ore choice: neither is reissued while either runs as a contract. All stop once Beat 6 is met; until then they do not expire, and a declined one is reissued the next day. The pending-offer cap of four is respected: if it is full, the reissue waits.
- Starter offers bypass the random-offer daily roll and do not use its slot.

### Business pot and payday

- New state subtree `business` (pure data):

  ```
  business: {
    potActive: bool,          # true from Beat 3 on
    pot: int,                 # £ held for the business
    week: { startDay, receipts, expenses: [{kind, contactId?, contractId?, amount}] },
    partners: [contactId],    # ["archie","james"] from Beat 3
    wages: { owen: { weekly: 250, owed: int, unpaid: bool, hiredDay: int } },
    ledger: [ {payday, receipts, expenses, shares:{player, archie, james}} ],  # history
    nextPaydayId: int
  }
  ```

- **Settlement routing:**
  - While `potActive`, every BizBrief contract settlement credits the pot and `week.receipts`, not player cash.
  - Before Beat 3, settlement credits player cash as now.
  - A contract's routing is decided by the day it settles, not the day it was accepted.
  - Sales outside BizBrief are never routed to the pot.
- **Calc purchases:**
  - Per-contract toggle `buyCalc` (beside each contract card, delegated contracts only).
  - When set, at the Sales delivery check the shortfall is bought and paid from the pot. The shortfall is:
    - ore requests: remaining qty minus available shared stock;
    - crafted requests: remaining units × the per-unit calc cost of the **lowest-cost producer currently in Production**, minus shared stock of that ore.
  - **Source = the cheapest calc available to the player right now.** Candidates are every ore-selling trade lane the player can currently buy from (faction lanes via the existing faction buy-price and max-quantity functions, so relation-driven spread discounts apply automatically), ranked by unit price. Ties go to the lane order in the faction trade data. If the cheapest source's available quantity is too small, the rest is bought from the next cheapest. Stock and relation side effects are exactly those of the player buying from that lane.
  - Bought ore enters shared stock, which triggers the normal delivery re-check.
  - A purchase the pot cannot cover in full is skipped entirely (no partial buy). Recorded as a `calc` expense naming the source.
- **Payday:** at the rollover where `day % 7 == 0`, after due contract settlements:
  1. Wages due = Owen's weekly wage, prorated `round(250 × daysWorkedThisWeek / 7)` for his first partial week, plus any `owed`. No wage accrues for days when he was unpaid.
  2. Pay wages from the pot. On a shortfall: record `owed`, set `unpaid = true` (Owen stops acting at block ends), and surface a "Pay Owen from your own cash?" prompt in the morning BizBrief. Yes → pay from player cash, clear owed, resume work. No → he stays unpaid.
  3. Every later rollover retries the owed amount from the pot; BizBrief shows "Pay now" (player cash) while owed. Paying the full owed amount resumes him.
  4. Remainder `R = pot` after expenses. Each partner share = `floor(R / 3)`. Player gets `R − 2 × floor(R / 3)`. Player share → cash + bank record. Partner shares leave the game.
  5. Pot → 0. Append a ledger record. Start a new week.
- The Morning Brief on a payday shows receipts, the expense lines (wage, calc), and the three shares. Payday processing uses stable ids, and a record is written before any cash moves (the same idempotency pattern as contract settlements).

### Unattended proof

- Each active contract period carries `playerAssisted: bool`, reset at every period start. It is set true when, during that period, the **player** does any of the following:
  1. makes a manual delivery to that contract;
  2. crafts the recipe that contract requests;
  3. cultivates or prunes a vein assigned to any cultivator;
  4. unstashes the requested item or ore type into shared stock;
  5. buys the requested ore type through any player purchase path.
- Sales' automatic calc purchases never set it.
- A period **qualifies** when the contract is recurring, delegated for the whole period, settles `complete == true`, has `playerAssisted == false`, and settles after the Beat 6 flag. Short first periods qualify.
- The settlement record stores `qualified: bool`. The Beat 6 evaluator counts distinct contract ids with ≥ 1 qualified settlement (≥ 2 needed, ≥ 1 of them a crafted-item request). The two contracts need not qualify in the same week.

### Owen's crafting event

- Trigger: Owen `cultivatingSkill ≥ 2` AND James recruited AND `workshop` in `home.rooms`. Checked at event completion and rollover. It plays once.
- On completion, Owen may be assigned Production. Swapping between Cultivation and Production is free and immediate, taking effect at the next block end. While he crafts, his veins keep their assignment list but have no active cultivator.
- It is not required for Act 1 completion.

### BizBrief

- **Staff tab** (third tab, visible from Beat 3):
  - Lists every recruited contact from the single contacts state: role, skill levels, XP, caps, pay terms ("⅓ share" / "£250 a week" / daily wage), and a working/unpaid status.
  - Includes the role assignment control, and the Pay now action while Owen is owed.
  - Links to Manage → Procurement for vein selection. It holds no roster state of its own.
- **Manage → Sales:** delegation toggle (after Beat 6) and the per-contract `buyCalc` switch.
- **Manage → Procurement:** existing vein picker and targets, now listing every cultivator.
- **Brief:** the payday statement and the pay-from-cash prompt.
- Screens stay read-only on state and call system functions only.

### Modules touched

- Contacts: roles, founders, caps, save fix-ups.
- Rooms: staff block step for cultivators and producers.
- Payroll: skip founders.
- Contracts: settlement routing, `playerAssisted`, `qualified`, `buyCalc`.
- Offers: starter chain, recurring scripted offers.
- TimeSystem: block hooks and rest.
- New Business system: pot, payday, wages owed.
- Objectives: new evaluators.
- Todo: business section.
- Crafting, Cultivating, stash and purchase paths: player-action taint hooks.
- MorningAccounts: payday summary.
- BizBrief: Staff tab and controls.
- Events data: 6 new events.
- Update REFERENCE.md §2, §3.10, §3.8 and CODEMAP.md in the landing tickets.

## Testing Decisions

- **Good tests assert external behaviour only:** the resulting `GameState.state` after driving the game through its public entry points. Never private helpers or internal call order.
- **Primary seam: time.** `TimeSystem.advance_time_block()`, `do_rest()` and `daily_tick()` drive days. Tests assert on `business`, `contacts`, `sales`, `player.cash`, objectives and flags. This covers per-block staff actions, rest giving the skipped blocks their actions, payday after settlement, pot routing, owed wages and resumption, and the Beat 6 proof end to end.
- **Secondary seam: player actions** through the same public calls the UI uses: `Offers.accept_offer` / `decline_offer`, `Contracts.deliver` / `set_delegated` / the `buyCalc` setter, player cultivate / prune / craft / unstash / buy, role assignment, `Business` pay-now, and event completion via the event runner. Taint must be exercised through these real calls, never by writing `playerAssisted` directly.
- **Supplementary pure checks** (not a seam) where a rule is fiddly: the cultivator's vein pick (furthest outside band, ties by order, idle), the three-way split rounding, and prorated first-week wage.
- Must-have scenarios:
  - three contracts completed before the pitch satisfy Beat 2 instantly;
  - a Workshop built earlier satisfies Beat 4's room check;
  - an expired starter reissues after one day;
  - Owen reaches cultivating level 2 but never passes 3;
  - a declined wage prompt stops Owen, and a later full payment resumes him;
  - a player manual delivery disqualifies that period only;
  - Sales calc purchases do not disqualify;
  - a short first period qualifies;
  - a save with Archie in a room loads as the Sales role;
  - an old save past the home raid loads with Archie recruited;
  - James already recruited before Beat 5 → the scene plays with no double effects;
  - Beat 1 fires at two veins with no Collective progress;
  - Sales buys from the cheapest lane and spills over to the next when stock runs out;
  - one cultivator with more veins than it can keep in band falls behind;
  - the full act alongside Collective Act 2 flags.
- Prior art: `tests/test_contracts.gd`, `test_offers.gd`, `test_payroll.gd`, `test_rooms.gd`, `test_objectives.gd`, `test_todo.gd`, `test_collective.gd` (questline triggers and backstops), `test_time_system.gd`, `test_phone_bizbrief.gd` (screen reads state, calls systems).

## Out of Scope

- Guild-sourced contracts, Guild membership or invitation, Guild consequences of Owen's placement, and the Dials hierarchy exposition.
- More hires, their wage rates, and expanded facility capacity scaling (rooms giving more staff or throughput).
- Retained earnings, reinvestment, and a player-managed business bank account.
- Higher-volume or quality-sensitive orders.
- Any change to James jobs (they continue unchanged) or to Archie's lane and faction trade.
- A named company or in-world business name.
- Combat roles for Owen.
- Balance tuning of contract prices beyond checking that two realistic recurring contracts leave a positive weekly player share after Owen's wage.

## Further Notes

- **Balance sanity check (for the tickets):** a Time Pearl sells for £120, quoted at ×1.25 = £150, so the 5-a-week order ≈ £750/week. Add a 6-a-week ore order and weekly receipts comfortably exceed Owen's £250. The player share ≈ (receipts − 250) / 3, rounding in the player's favour. Verify with the live quote.
- **Changes to existing behaviour, deliberately accepted:**
  - the Vein Station and Lab move from once-daily to one action per block for **all** staff;
  - station cultivator XP drops to 2 per action;
  - Archie and James lose relation recruitment;
  - owed wages are now carried until paid, replacing the vision's "no wage debt" for Owen.
- **Beat 1 no longer follows Collective Act 1** (the vision said it did). It fires at two veins whatever the player's Collective progress.
- **Business purchases never read the player's location.** Every faction lane has `applyDistrictPriceMod: false` today. Price the business's candidates without any district modifier, even if a lane later turns it on. Removing player location from the game as a whole is a separate effort, outside this spec.
- Suggested ticket order:
  1. roles, founders and caps, with save fix-ups;
  2. the per-block staff step;
  3. the business pot and payday;
  4. the offer catalogue and starter chain;
  5. taint tracking and qualification;
  6. objectives, ToDo and events for Beats 1–7;
  7. the Staff tab;
  8. Owen's crafting event;
  9. the full-path test alongside Collective Act 2.
