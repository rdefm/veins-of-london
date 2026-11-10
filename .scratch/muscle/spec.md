# Spec — Muscle (hired guards and soldiers)

Status: ready-for-human — awaiting human approval. Flips to `ready-for-agent` on approval; ticket breakdown only after that.

Source: grilling ticket `.scratch/raid-events/issues/29-grilling-muscle.md` (decisions 1–47, sessions 1–3, 2026-11-09/10). Merged with `.scratch/security-officer/spec.md` (decided 2026-11-10: one room, officer seat stacks on guard levels).

## Decisions (summary)

All numbers are *placeholders* for the economy/balance pass unless stated.

**Model**
- **Muscle wraps today's guards** and is the only source of guard bodies. `vein_guard_count`, `get_guard_count`, faction stockpile guards and every consumer (resist, repel, kit capacity, raid enemy count, wages) read derived values. No parallel count.
- **Player muscle = individual guard records**, their own entity under `state.muscle`, not contacts. Contacts stay the named-people layer, and LodedInnit stays skilled staff.
- **Faction muscle = counts by level**, sim-only.
- **Old saves are not supported.** Save version bump, no migration.

**Security Office (room)**
- One new HQ room, the **Security Office** (`securityOffice`).
  - minTier townhouse, £2,500, uses a room slot.
  - It has one optional **Security Officer** seat (officer spec, rebased below).
- **No player guards anywhere until it's bought.** That covers vein posts and HQ posts. The vein `guarded` tier and "+1 guard" are removed, and the HQ "Hired Guard" compound gate goes.
- **Buying it fires the intro event** on the next HQ visit: Archie says they need help and has called Arnie, and Arnie walks the player through guard management.
  - **Arnie appears nowhere else.** No avatar or line on the board, no named training venue, no system text naming him.
- **`flags.securityContactUnlocked` is unchanged** (the prologue ×0.7 HQ hardware discount).
- **Losing the room** (arrears downgrade below townhouse, no free slot on a tier move, or replaced):
  - guards stay employed; posts, wages and fights keep running
  - management is locked; vein posts freeze; HQ guards drop to Reserve below townhouse
  - Short Pay still works
  - one notification
  - re-buying restores management, and the intro doesn't replay
- **The screen is called "Security"** and is opened from the room. Hardware (lock/cameras/door/alarm/ward) stays in the HQ diorama Security zone. No company name is needed.

**Screen**
- Tabs:
  - **Posts**: place-centric (HQ / each vein / Reserve).
  - **Guards**: person-centric list, a detail sheet and Hire.
  - **Costs**: Guard Costs moves here from BizBrief.
- **Posting from three entry points, one system function:** Posts "+ Assign" / "→ Reserve", the Guard detail "Post ▾", and the vein detail panel "+ Assign" / "Manage ›".
- With an empty Reserve, "+ Assign" shows "No one in reserve — Hire ›".
- Other screens become readouts plus deep links: HQ door guard tile, vein panel, HQ guard kit list, BizBrief totals/Brief rows.

**Hiring**
- A board of **4 candidates, refreshed every Monday.**
  - A hired card stays empty until the next refresh. No re-roll, no quick-hire.
- Each card rolls its level on its own from fixed odds (not HQ tier).
  - 10% of cards are a **former guard** (dismissed or walked off), if any exist. They come back as they left (name, level, XP, traits), with injuries cleared, tagged "Worked for you before".
  - `muscle.former` is capped at 20, oldest dropped.
- **Dismiss:** confirm, immediate, no severance, no refund. Allowed while injured. The guard goes to former.

**Levels, wages, XP, training**

| Lvl | Weight | Wage/wk | Board odds | XP to reach |
|---|---|---|---|---|
| 1 | 1.0 | £500 | 50% | 0 |
| 2 | 1.25 | £600 | 30% | 50 |
| 3 | 1.5 | £750 | 15% | 100 |
| 4 | 1.75 | £900 | 5% | 200 |
| 5 | 2.0 | £1,100 | 0% (training only) | 400 |

- Wage is set by level only (traits can modify it).
  - The hire advance, Monday bill and grace day work as today, summed per person.
  - Reserve and injured guards are paid.
  - A new wage applies from the next Monday bill.
- **XP:**
  - +1/day on a post; Reserve earns 0
  - +5 per successful repel
  - +3 per guard who fights in a defend fight (win or lose)
  - a level-up sends a notification
- **Training:** "Train ›" on the Guard detail sheet.
  - Costs £200 × current level, gives +10 XP, and the guard is away 1 day (off post).
  - No player time block, no session cap.

**Traits**
- Every guard has at least one, fixed for life.
- 25% of cards roll a second, distinct one. Blocked pairs: Solid+Glass jaw, Quick study+Slow learner, Watchful+Flaky, Quick study+Lazy.
- Effects stack multiplicatively.

| Trait | Kind | Effect |
|---|---|---|
| Quick study | + | XP ×1.5, all sources |
| Brawler | + | Fight attack ×1.25 |
| Solid | + | Fight HP ×1.25 |
| Watchful | + | +0.25 weight, repel only |
| Hard to keep down | + | Injury 1 day, not 3 |
| Cheap | + | Wage ×0.8 |
| Mouthy | mixed | Wage ×1.1, +0.25 weight, repel only |
| Hothead | mixed | Fight attack ×1.25, HP ×0.8 |
| Flaky | − | −0.25 weight, repel only |
| Glass jaw | − | Fight HP ×0.75 |
| Slow learner | − | XP ×0.5 |
| Lazy | − | No passive XP on post |
| Light-fingered | − | 10% each Monday: 1 kit unit at their post goes missing |

**Posts and numbers**
- **Posts:** each vein and HQ (cap 4 each); Reserve is uncapped.
  - Moves are instant, free, no cooldown (any time block).
  - Training and injured guards are off post.
- **Vein resist** = lock/ward tier (0/15/35) + Σ over posted guards (20 × weight + officer resist bonus).
- **Repel** = min(Σ 0.15 × repel weight + count × officer repel bonus, 0.75 + officer cap bonus).
  - Kit adds its existing bonus up to the 0.90 kit cap.
  - Repel weight = level weight + trait repel modifiers.
- An all-L1, no-officer roster gives today's numbers.
- **Equipment = the existing place kits only.** Capacity = posted bodies × slotsPerGuard.
- **Guard ally fight stats** = `guardAlly` block × weight × trait multipliers + officer ally bonus, rounded. Shows the guard's name and level.
- **One Security score (0–100)**, a readout only:
  - Score = round(40 × hardware ÷ the place's max hardware + 60 × min(1, repel ÷ 0.75)).
  - Vein hardware = lock/ward resist (max 35). HQ hardware = installed `raidReduction` (max 0.18, excluding guard).
  - Bands: 0–24 Exposed / 25–49 Light / 50–74 Solid / 75+ Fortified.
  - Shown on the vein detail panel and the Posts headers.

**Fights, alarms, loss**
- In a defend fight, posted guards fight from round 1.
- **Up to 2 Reserve guards join at round 3** through the existing reinforcement queue (`reserveResponders`), highest level first, not injured.
- **Undefended/expired alarms:** the same responders add their repel weight to that place's repel roll.
- **Each Reserve guard answers at most one alarm per time block.**
  - Priority: the fight the player defends, then HQ, then veins by `value_order` (most valuable first).
  - Alarms rows show "Reserve: 2 responding" / "Reserve: none free".
- **Injury:** a guard ally knocked to 0 HP (win or lose) is Injured for 3 days.
  - Dropped to Reserve; can't be posted or trained; paid; no passive XP.
  - Tag "Injured · Nd".
  - A repel never injures. No deaths.
- **Guards never transfer with a vein.**
  - A vein taken by force: its guards go to the owner's Reserve, unhurt.
  - Sell/buy moves no guards.
  - A vein the player takes arrives with no guards.
- **Short Pay** becomes a per-person keep checklist.
  - Auto-resolve drop order: Reserve first (injured included), then posts on the least valuable vein first, then HQ; lowest level first within a place.
  - Walked guards go to former.

**Factions**
- Faction veins and stockpiles hold `guards: [n1..n5]`, plus a faction Reserve and an injured list.
- Hire level rolls a per-faction `muscleOdds`. No faction XP or training.
- Wages use the same level table; walk-off goes lowest level first.
- **Daily security buy order:** lock → ward → fill vein posts (cap 4, highest value first) → stockpile target → Reserve target (`reserveGuards`). Factions lose the `guarded` tier.
- **Losses:**
  - A guard defeated in a player raid fight is out 3 days, then returns to Reserve.
  - A taken vein's guards go to the faction's Reserve.
  - Rivalry: the loser of the attempt loses 1 guard to injury.
  - Walk-off as today.
- **Raid reinforcements:** when the clock fires, up to 2 come from the owner's Reserve, highest level first.
  - An empty Reserve means none come ("No one came." variant if the event has one, else the card is skipped).
  - The raid's starting guards = that vein's posted guards; the stockpile raid uses the stockpile guards.
  - Sites with no owner faction keep the event's flat +2.
- **Visibility:**
  - Observing shows guard count + a strength word from the average weight per guard: green <1.25 / hardened <1.75 / seasoned ≥1.75. The security signature includes levels.
  - Enemy guards show their level in fights.
  - Faction Reserve size stays hidden.

**Names**
- A data pool of about 60 first names and 60 surnames (London mix), plus a nickname list (generic and funny).
- 15% of guards get a nickname, shown as Dee "Spanner" O.
- List rows show the first name and surname initial; the detail sheet shows the full name.
- No repeats among current and former guards.

## Problem Statement

Guards are anonymous £500/week units bolted onto places: a vein security tier, an `extraGuards` count, an HQ guard count, a faction stockpile number. Once the player has a few, the only lever is "hire more". Guards can't get better, can't be moved between places, can't answer an alarm, and never feel like people. Factions hold the same flat counts, so the guards the player fights in a raid and the reinforcements that arrive are placeholders (a flat +2), unrelated to anything the faction owns or has lost. Guard management is scattered across the vein panel, the HQ door, BizBrief's Guard Costs and the Short Pay sheet.

## Solution

Guards become **muscle**: named people the player hires from a weekly board, posts to veins or HQ or keeps in Reserve, and levels up through time on post, fights and paid training. Each guard has a level (1–5) and one or two traits that change how they fight, repel, learn and cost. Buying a new HQ room, the **Security Office**, opens a single **Security** screen (Posts, Guards, Costs) where all of it happens, introduced once by Arnie. Reserve guards answer alarms: they join defend fights at round 3 or bolster an unattended repel, one alarm per guard per time block. Injuries take guards out for three days; nobody dies. A single Security score per place makes "how safe is this" readable at a glance.

Factions run the same economy in counts: they hire guards at levels set by their own profile, post them on veins and stockpiles, keep a Reserve, lose guards to injury and unpaid wages, and send real reinforcements from that Reserve when a raid's alarm clock runs out. Bleeding a faction's Reserve before a raid becomes a tactic.

The optional Security Officer (existing spec) sits in the Security Office's one seat and stacks flat per-guard bonuses on top of guard levels.

## User Stories

**Unlock and the room**
1. As a player, I want to buy a Security Office from the HQ room list once I'm in a townhouse, so that security is an HQ upgrade like any other room.
2. As a player, I want the Security Office to cost a room slot, so that taking it is a real choice against a workshop or library.
3. As a player, I want Archie to tell me we need help with security and bring in Arnie after I buy the room, so that the new system arrives in the story.
4. As a player, I want Arnie to walk me through hiring, posting, Reserve and costs in that one event, so that I know how to use the screen.
5. As a player, I want the Security screen to work from the moment the intro ends, with no further chat-thread steps, so that managing guards is pure tooling.
6. As a player, I want to open the Security screen from the Security Office in my HQ, so that I know where security lives.
7. As a player, I want guard posting to be unavailable before I own the room, so that the room is clearly what unlocks guards.
8. As a player, I want a clear hint in places where guards would appear (vein panel, HQ door) that guards need a Security Office, so that I can find the feature.
9. As a player, I want my guards to keep their jobs if I lose the room through arrears or a move, so that one bad week doesn't wipe out months of levelling.
10. As a player, I want a notification when I lose the room saying my guards hold their posts but can't take new orders, so that I understand the lockout.
11. As a player, I want Short Pay to keep working without the room, so that I can always choose who to keep paying.
12. As a player, I want re-buying the room to restore management without replaying the intro, so that it isn't repetitive.
13. As a player, I want lock, cameras, door, alarm and ward to stay in the HQ Security zone, so that hardware and people stay separate.

**Hiring board**
14. As a player, I want four guard candidates on a board each week, so that hiring is a choice and not a vending machine.
15. As a player, I want the board to refresh every Monday, so that it fits the weekly wage rhythm.
16. As a player, I want a hired candidate's slot to stay empty until Monday, so that taking someone has a cost.
17. As a player, I want each card to show name, level, weekly wage and traits, so that I can compare candidates at a glance.
18. As a player, I want candidate levels to be a random mix that doesn't depend on my HQ tier, so that good guards are something I pay for, not something I unlock.
19. As a player, I want level 5 guards to be unhireable, so that a level 5 is something I build.
20. As a player, I want dismissed or walked-off guards to sometimes reappear on the board as they left, so that I can rehire someone I know.
21. As a player, I want a "Worked for you before" tag on a returning guard, so that I recognise them.
22. As a player, I want the vein panel's Assign with an empty Reserve to offer "Hire ›" straight to the board, so that I'm one tap from fixing it.

**Guards as people**
23. As a player, I want each guard to have a generated name, sometimes with a nickname, so that my roster feels like people.
24. As a player, I want short names in lists and full names on the detail sheet, so that rows fit a phone screen.
25. As a player, I want no two current or former guards to share a name, so that I can tell them apart.
26. As a player, I want every guard to have at least one trait, sometimes two, so that two guards of the same level differ.
27. As a player, I want negative traits as well as positive ones, so that a cheap-looking card can be a trap and a mixed card a gamble.
28. As a player, I want to tap a trait to see its one-line effect, so that I know what it does.
29. As a player, I want contradictory trait pairs never to appear together, so that a guard never reads as nonsense.
30. As a player, I want to dismiss a guard with a confirmation, so that I can stop paying someone I don't need.

**Posting**
31. As a player, I want a Posts tab grouped by HQ, each vein and Reserve, with count, weekly cost, kit status and Security score, so that I see my coverage by place.
32. As a player, I want "+ Assign" on each place to pick from Reserve, so that posting is quick.
33. As a player, I want "→ Reserve" on a posted guard, so that I can pull them back.
34. As a player, I want a Post picker on the Guard detail sheet listing HQ, every vein and Reserve, so that I can move a guard post to post directly.
35. As a player, I want "+ Assign" and "Manage ›" on the vein detail panel, so that I can post guards from the map.
36. As a player, I want moves to be instant, free and repeatable every time block, so that reacting to threats isn't punished.
37. As a player, I want a cap of four guards per vein and four at HQ, so that guard quality matters more than numbers.
38. As a player, I want an unlimited Reserve, so that I can hold guards on call or in training.

**Levels, XP and training**
39. As a player, I want guards to level from 1 to 5, so that I can see them grow.
40. As a player, I want posted guards to earn a little XP each day, so that loyal guards improve on their own.
41. As a player, I want guards to earn XP for repelling a raid and for fighting in a defence, so that action makes them better.
42. As a player, I want Reserve guards to earn no passive XP, so that guards sitting idle don't improve.
43. As a player, I want to pay for a training session from a guard's detail sheet, so that I can speed up a promising guard.
44. As a player, I want training to cost more at higher levels, so that a level 5 is a real investment.
45. As a player, I want a guard in training to be away from their post for a day, so that training has a security cost unless I train from Reserve.
46. As a player, I want no limit on training sessions, so that I can push a guard as hard as I can afford.
47. As a player, I want a notification when a guard levels up, so that I notice the growth.
48. As a player, I want XP and the next level threshold on the detail sheet, so that I know how close a guard is.

**Wages and costs**
49. As a player, I want a guard's wage to depend on level (and wage traits), so that better guards cost more.
50. As a player, I want a level-up's new wage to apply from the next Monday bill, so that the bill is predictable.
51. As a player, I want hiring to take the same prorated advance as today, so that hiring mid-week isn't overpriced.
52. As a player, I want Reserve and injured guards to be paid, so that on-call muscle is a real cost.
53. As a player, I want a Costs tab with the next Monday bill, this week's wages and training, and a per-place history I can expand per guard, so that I see where the money goes.
54. As a player, I want Short Pay to be a checklist of guards by post with wages and a running total against what I can pay, so that I choose exactly who stays.
55. As a player, I want unpaid auto-resolve to drop Reserve first and low levels first, so that my best posted guards are protected by default.
56. As a player, I want BizBrief to show guard totals and deep-link to Costs, so that the business view still adds up.

**Security score and readouts**
57. As a player, I want one 0–100 Security score per vein and HQ with a word band, so that I can read safety at a glance.
58. As a player, I want the score to weigh guards more than hardware, so that locks alone never look like full security.
59. As a player, I want the score on the vein detail panel and Posts headers, so that I see it where I make decisions.

**Fights, alarms and injury**
60. As a player, I want my posted guards to fight beside me from round 1 when I defend, so that posting matters in a fight.
61. As a player, I want guard allies to show their name and level and fight harder at higher levels, so that levelling shows up in combat.
62. As a player, I want up to two Reserve guards to join a defence at round 3, so that Reserve answers the alarm.
63. As a player, I want Reserve guards to bolster the repel roll on an alarm I can't attend, so that a Reserve is useful when I'm busy.
64. As a player, I want each Reserve guard to answer only one alarm per time block, so that a big Reserve matters when several alarms hit at once.
65. As a player, I want responders sent to the fight I'm in first, then HQ, then my most valuable veins, so that the automatic choice is sensible.
66. As a player, I want the Alarms list to show how many Reserve guards are responding or that none are free, so that a shortfall is visible before it resolves.
67. As a player, I want a guard knocked out in a fight to be injured for three days, so that fights cost something.
68. As a player, I want injured guards shown with a countdown and blocked from posting and training, so that I plan around them.
69. As a player, I want no guard deaths, so that losing a long-levelled guard isn't one bad roll.
70. As a player, I want guards on a vein I lose by force to fall back to Reserve, so that I keep the people even if I lose the place.
71. As a player, I want buying or selling a vein never to move guards, so that a vein deal is only about the vein.

**Kits**
72. As a player, I want guard kits to stay per place, with capacity from the number of guards posted there, so that the kit sheet I know keeps working.
73. As a player, I want a light-fingered guard to occasionally lose a kit unit at their post, so that the trait has a real sting.

**Factions and raids**
74. As a player, I want faction veins to hold guards of different levels, so that some targets are much tougher than others.
75. As a player, I want different factions to field different-quality muscle, so that factions feel distinct.
76. As a player, I want the guards I fight in a raid to be the vein's actual posted guards, so that what I scouted is what I face.
77. As a player, I want raid reinforcements to come from the owner faction's Reserve, so that the alarm clock has real stakes.
78. As a player, I want no reinforcements to arrive when the faction's Reserve is empty or busy, so that draining it first is a tactic.
79. As a player, I want faction guards I defeat to be out for a while, so that hitting a faction thins its muscle.
80. As a player, I want factions to lose guards to unpaid wages and rival raids, so that faction strength moves with the world.
81. As a player, I want observing a faction site to show its guard count and a green/hardened/seasoned strength word, so that I can judge a target without perfect information.
82. As a player, I want a site to read as changed when its guards level or are swapped, so that observation stays honest.
83. As a player, I want enemy guards to show their level in fights, so that I know what I'm up against.
84. As a player, I want raids on sites without an owner faction to keep their authored reinforcements, so that set-piece events still work.

**Security Officer (merged)**
85. As a player, I want the Security Office's one seat to hold an optional Security Officer, so that a good officer improves every guard I have.
86. As a player, I want officer bonuses to add on top of guard levels, so that an officer and a levelled roster both count.
87. As a player, I want a founder officer to work without the room, but guard management to still need it, so that both rules stay clear.

**Integrity and data**
88. As a player, I want Rewind and save/load to restore my roster, posts, XP, injuries, board and former guards exactly, so that the flagship feature stays intact.
89. As a designer, I want every muscle number (level table, XP, training, traits, caps, responders, score weights, board size, odds, name pools) in JSON, so that balance never needs a code change.
90. As a designer, I want an all-L1, no-officer roster to give exactly today's resist, repel and ally numbers, so that existing balance and tests hold.
91. As a designer, I want old saves refused cleanly by a save version bump, so that no half-migrated guard state exists.

## Implementation Decisions

**Seam: one new system module, `Muscle`** (static funcs over `GameState.state`, emits `EventBus.state_changed`, never touches nodes). It owns all muscle rules for the player and factions. Consumers ask it; nothing else reads `state.muscle` or faction muscle fields directly.

Player interface (shape, not final names):
- Roster reads: `guards()`, `guard(id)`, `guards_at(post)`, `reserve()`, `is_available(id)` (not injured, not training), `short_name(id)`.
- Weights: `weight(id)` (level), `repel_weight(id)` (level + trait repel modifiers), `post_weight_sum(post)`, `post_repel_weight_sum(post)`.
- Board: `board()`, `roll_board()` (Monday), `hire(card_index)` (pays the advance via `GuardUpkeep`).
- Posting: `can_manage()` (room owned), `post(id, post)`, `cap(post)`. One function backs every entry point.
- Lifecycle: `dismiss(id)`, `train(id)`, `award_xp(id, source)`, `injure(id)`, `daily_tick()` (passive XP, injury and training countdowns, light-fingered roll on Mondays).
- Alarms: `claim_responders(place, block)` → up to `reserveResponders` guard ids, with the one-alarm-per-block ledger and priority order.
- Readouts: `security_score(place)` → `{score, band}`, `strength_word(faction vein)`.
- Room loss: `on_room_lost()` (HQ posts to Reserve below townhouse; lock flag via `can_manage()`).
- Vein loss: `on_vein_lost(vein)` → posted guards to the owner's Reserve.

Faction interface: `faction_guards_at(vein|stockpile)`, `faction_reserve(faction)`, `faction_hire(faction, place)` (rolls `muscleOdds`), `faction_injure(faction, level)`, `faction_draw_reinforcements(faction, block)`, `faction_daily_tick()` (injury returns).

**State schema** (pure data, no objects):
```
state.muscle = {
  nextId: int,
  guards: [{ id, name, nickname, level, xp, traits:[String], post: "home"|veinId|"reserve",
             injuredUntilDay: int, trainingUntilDay: int }],
  board: { day: int, cards: [ {guard record} | null ] },   # 4 slots, null = hired
  former: [ {guard record} ],                               # cap 20, FIFO
  responders: { block key: [guard ids] }                    # cleared each block
}
faction vein / stockpile: guards: [n1, n2, n3, n4, n5]
faction.muscle = { reserve: [n1..n5], injured: [{ level, returnsDay }], respondersBlock: ... }
```
The schema above is a sketch of the decided shape. The implementer may rename fields, but must keep it all primitive.

**Wrapped functions** (signatures kept, now derived from `Muscle`):
- `Cultivating.vein_guard_count(vein)`: player vein = available guards posted there; faction vein = Σ counts.
- `Cultivating.vein_raid_resist(vein)` = lock/ward tier resist + Σ(20 × weight) + count × officer resist bonus (player only).
- `Raiding.guard_repel_chance` takes a repel weight sum (plus officer bonus, player only). Faction calls use count-by-level weights.
- `Home.get_guard_count()` = available guards posted at HQ. HQ raid-chance per-guard reduction: see Further Notes (open).
- Faction stockpile guard count = Σ stockpile counts.
- `GuardKit` capacity keeps reading guard count (bodies).
- `Combat.build_guard_ally` takes a guard (or a faction level) → block × weight × trait multipliers + officer ally bonus; name and level on the combatant.

**Removed**
- The vein `guarded` security tier: player and faction tiers top out at warded.
- Player `extraGuards`, `home.guardCount` and the HQ "Hired Guard" security item gate.
- Faction `extraGuards` is replaced by `guards` counts. `maxExtraGuardsPerVein` is replaced by the post cap 4.
- The vein-panel "+1 guard" purchase.

**GuardUpkeep**
- Monday bill = Σ per-guard wage (level wage × trait wage multipliers).
- Advance = that guard's wage prorated.
- Shortfall `places` becomes per-guard ids. The Short Pay keep is a set of guard ids.
- Auto-resolve drop order: Reserve (incl. injured) → posts by least valuable vein → HQ, lowest level first in each place.
- Walked guards → `former`.
- Faction bills: Σ counts × level wage, walk-off lowest level first across vein posts → stockpile → Reserve.
- History stays per place (`home` / vein id / `reserve`) plus a training line.

**Faction sim**
- `Factions.apply_security_upgrades` buy order: lock → ward → fill vein posts to cap (highest `vein_value` first) → stockpile to `stockpileGuards` → Reserve to `reserveGuards`. Each hire rolls `muscleOdds` and needs the existing wage reserve.
- Rivalry resolution injures 1 guard of the losing side (the raided vein's posts on success, the attacker's Reserve on failure).
- `factions.json` gains `muscleOdds` and `reserveGuards` per faction.

**Raids and alarms**
- Ticket 23's reinforcement clock calls `faction_draw_reinforcements` for the site's owner. It takes up to `reserveResponders`, highest level first, and fewer or none if the Reserve is empty or already answered this block. Zero → the event's "No one came." variant card if authored, else the arrival card is skipped. Ownerless sites keep the event's flat count.
- Raid start: enemy guards = the vein's posted counts by level (stockpile raid: stockpile counts).
- Defeated enemy guards → `faction_injure`.
- Player defend fights (`home_alarm_defend`, vein defend) seed posted guards as round-1 allies. `claim_responders` guards enter at round 3 via the existing reinforcement queue.
- Allies at 0 HP → `injure`. Survivors and the fallen both get defend-fight XP.
- Undefended/expired alarm resolution adds claimed responders' repel weights to the place's repel roll.
- Responder XP: a successful repel gives +5 to every guard whose weight counted (posted + responders).

**Observation**
- `security_signature` includes level counts.
- The observe read adds the strength word.
- Combat cards show the enemy guard level.

**Security Office room and officer merge**
- `home.json` room `securityOffice`: cost 2,500, minTier townhouse, 1 seat (officer), no seat upgrades. This replaces the officer spec's "lowest tier with slots" minTier.
- Buying it sets the intro-event trigger.
- `Muscle.can_manage()` = room owned. A founder officer still needs no room (`roomFreeRoles`), but management does.
- Officer bonuses rebased per body (they no longer replace anything):
  - resist: + `guard_raid_resist_bonus()` per posted guard
  - repel: + `repel_bonus_per_guard()` × count and + `repel_cap_bonus()`
  - ally: + `guard_ally_bonus()`
  - HQ: `hq_guard_raid_reduction_mult()` as in that spec
- The officer's Train boost applies to the player's own Train only, not guard training.
- The officer spec's "save backfill" and "anonymous guards unchanged" lines are superseded (no old saves; guards are muscle).

**Screens** (read state, call `Muscle`/`GuardUpkeep` only)
- **New Security screen** (Posts / Guards / Costs), opened from the Security Office tile.
  - Guard detail sheet: stats, traits, XP/next, wage, Post picker, Train, Dismiss.
  - Hire board sheet.
  - The Short Pay checklist reuses the sheet pattern.
- **Vein detail panel:** guard row with count, Security score, "+ Assign" / "Manage ›", plus the empty-Reserve hire link and the no-room hint.
- **HQ door Security zone:** keeps hardware. The guard tile becomes a readout plus deep link (and the no-room hint).
- **BizBrief:** Guard Costs leaves; totals and Brief rows deep-link to Costs.
- **Alarms rows:** a responder line.
- **Combat:** ally/enemy cards show name/level.

**Data** (all placeholders): a `muscle` block in `constants.json` covering:
- the level table
- XP awards and thresholds
- training cost/XP/days
- injury days
- post caps
- `reserveResponders`
- board size, odds, former chance and cap
- second-trait chance and nickname chance
- score weights, bands and strength-word cut-offs
- `guardAlly` stays the L1 block

Also new data files: `muscle_traits.json` (id, label, kind, one-line effect text, effect params, blocked pairs) and `muscle_names.json` (first names, surnames, nicknames).

**Save:** save version bump; older saves are refused with the standard message.

**Prose:** the intro event (Archie → Arnie tutorial) is one prose ticket under `docs/writing-guide.md`. The name/nickname pools, trait lines and UI strings get PROSE-REVIEW flags.

## Testing Decisions

- Good tests drive public system calls against a seeded `GameState.state` and assert on observable results (counts, odds, stats, wages, state fields). They never assert on private helpers or call order. Use seeded `Rng`. Set state directly instead of looping on game conditions; cap any loop.
- **Primary: a new `test_muscle.gd`** at the `Muscle` seam:
  - board roll: 4 cards, odds respected over a seeded run, no L5, former-guard 10% path, unique names, trait count and blocked pairs
  - hire pays the advance and empties the slot until Monday; dismiss → former; former cap 20
  - posting caps, instant moves, `can_manage()` false without the room; room loss: HQ posts to Reserve below townhouse, management locked
  - XP sources and trait multipliers, level thresholds 50/100/200/400, level-up notification, Lazy / Slow learner / Quick study
  - training cost by level, +10 XP, away 1 day, then back on post
  - injury: 3 days (1 with Hard to keep down), off post, unavailable
  - responders: max 2, highest level, one alarm per block, the priority order, the 3-alarms-4-Reserve case
  - security score bands, and examples (warded alone 40; warded + 1 L1 52)
  - strength-word cut-offs
  - faction hire by `muscleOdds`, injury returns, vein-loss fallback
- **Integration through existing suites:**
  - `test_guard_upkeep.gd`: per-person bill, advance, Short Pay checklist, auto-resolve drop order, faction bills by level
  - `test_raiding.gd`: all-L1 parity with today's resist/repel, weighted resist/repel, trait repel mods, responder repel weight, enemy guards from posts, reinforcement draw incl. empty / busy Reserve, ownerless sites flat +2
  - `test_factions.gd` / `test_faction_sim.gd`: buy order, post cap, Reserve target, rivalry injury
  - `test_combat_rounds.gd`: round-1 posted allies, round-3 responders, ally stats × weight × traits, KO → injury
  - `test_home.gd`: HQ guard count, room-gated HQ posts
  - `test_guard_kit.gd`: capacity from posted bodies, light-fingered loss
  - officer tests (from the officer spec): bonuses stack on weights
  - save: version bump refuses an old save; a Rewind round-trip restores roster, board and injuries
- Prior art: `test_guard_upkeep.gd` (guard math, bills), `test_raiding.gd` (seeded-Rng odds), `test_hiring.gd` (board-like hire flows, prepay), `test_combat_rounds.gd` (reinforcement queue), `test_faction_sim.gd` (daily sim steps).
- Run a new test file alone under `timeout 60` first. One targeted run per change, then one full suite + `check_all.sh` at the end.

## Out of Scope

- Per-guard gear or weapons (kits stay per place).
- Guard deaths or permanent loss in fights.
- Faction guard XP or training.
- Faction-rented muscle (relation-gated, recallable in war). Parked.
- A paid board re-roll.
- Network intel for faction Reserve size.
- Migration of pre-muscle saves.
- Final balance numbers.
- Any Arnie role after the intro event.
- Officer changes beyond the rebase above (the officer spec remains its own build).

## Further Notes

- **Open for approval:**
  - **(a) HQ raid chance:** should each HQ guard's `raidReduction` (0.05) scale by weight like vein resist does? The spec assumes yes (0.05 × weight); confirm.
  - **(b) Room naming:** the room is named **Security Office** (`securityOffice`) to merge with the officer spec, and the screen is "Security". Confirm the name.
- **Ordering:** muscle builds before the Security Officer spec; the officer spec's tickets are rebased onto `Muscle`. The officer spec needs its room minTier, backfill and out-of-scope lines edited to match (noted there).
- **Blocked by** (from ticket 29): 10 The Arches, 11 The Shop, 19 the `vein_raid` rebuild, 26–28 prose.
- **Doc updates** in the implementing commits:
  - REFERENCE.md §1.6 (guards, kit, upkeep), §1.8 (faction guard hiring/wages), §3.8 (alarm defend), §3.12 (vein raiding/reinforcements) and the daily-tick order (Muscle daily tick + board Monday roll)
  - CONTEXT.md: **Muscle**, **Post**, **Reserve**, **Responder**, **Former guard**, **Security Office**. Note that "Guarded" is the combat guard-state term, unrelated to the removed vein tier.
  - CODEMAP.md: the new system, screen and data files
- **PROSE-REVIEW:** the intro event, name/nickname pools, trait labels and lines, "No one came." variants, notifications, and the Security screen strings.
