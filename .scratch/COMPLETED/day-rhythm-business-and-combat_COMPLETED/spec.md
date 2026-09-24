# Day rhythm, actionable alarms, business progression, and combat

Status: ready-for-agent
Date: 2026-09-13
Scope: conversation synthesis; implementation planning and bounded prototypes before unresolved balance changes.

## Problem Statement

Vein's three daily actions do not yet feel like a day in London. Abbreviated time labels are unintuitive, and the daily rollover can conceal consequences beneath routine notifications. The dot-matrix board has a deliberate transport-sign identity and cannot become an action-button toolbar.

The desired progression is from struggling to pay bills and survive individual fights to operating an automated business empire, influencing the city, and clearing waves of enemies single-handedly. Repeated failed maintenance actions and artificial transaction requirements can make early play frustrating without teaching useful business decisions. Later, the same manual tasks risk becoming chores.

Combat needs readable choices beyond repeated attacks: fast and heavy attacks, countering, dodging, and exploiting exhaustion. These choices must support both vulnerable early play and overwhelming late-game preparation.

## Solution

### Day rhythm and time display

Retain three time blocks: Morning, Afternoon, Evening. Replace abbreviated phase text with the full phase name and day number, supported by a persistent sun/moon cue. A compact three-segment indicator identifies completed, current, and remaining phases without relying solely on colour.

Every successful action that consumes time produces one short, reusable London panorama interstitial. It lasts 1–2 seconds and is **not skippable**. Tapping cannot dismiss it or activate the screen beneath it. Use one park composition with distant London landmarks, a horizon, layered sky, sun/moon, and simple shadow animation rather than new artwork for every game screen or time phase.

- Morning to Afternoon: sun rises towards its high point; shadows shorten.
- Afternoon to Evening: sun lowers; shadows lengthen; a small window-light layer may illuminate.
- Evening to Morning: moon passage and sunrise communicate the overnight transition; the day number increases.
- Early Rest: show the current phase passing through night into the next morning, still within 1–2 seconds.
- Explicit destination text identifies the resulting phase/day. A phase symbol remains available after the interstitial for returning players.
- Reduced-motion presentation uses a gentle/static transition for the same duration, without introducing a skip control.

Resolve and communicate the action outcome before presenting the time transition. Do not interrupt an unresolved event choice, combat sequence, or result requiring acknowledgement. The visual transition must not itself execute gameplay effects.

Surface the last daily block on action labels and give a compact next-morning account of actual income, expenses, stock changes, losses, and urgent matters. Scale emphasis with progression: early cash pressure, later business output and exceptions.

The earlier suggestion of a separate manual “Finish day” state is **not a locked decision**. The accepted evening-to-morning interstitial can accompany the existing automatic rollover. Preserve automatic rollover for initial implementation; a manual closing state would require a separate rule decision, not a silent addition here.

### Urgent phone alarms and physical vibration

Keep the dot-matrix board informational. Pin unresolved urgent situations independently of notification recency. Put decisions in the phone.

When a new actionable raid alarm arrives, briefly animate the Phone tab vibrating and trigger **actual device vibration on supported mobile hardware**. Once the current interaction reaches a safe boundary, automatically open a phone alarm surface showing the vein, district, intervention deadline, and consequences.

Offer three clearly distinct responses:

- Go and defend: invoke the existing defence flow.
- Leave undefended: explicitly accept non-intervention, with the consequence explained before commitment.
- Decide later: dismiss the immediate alarm presentation while retaining its unresolved badge and pinned board warning.

Closing/backing out is equivalent to deciding later, never to abandoning defence. Group simultaneous alarms into one list. Reserve automatic opening and haptics for newly actionable urgent situations; routine messages and successful contracts should not interrupt the player.

Provide a vibration preference and graceful visual fallback on unsupported devices or when vibration is disabled. The feature is in-game feedback, not a background push-notification service.

### Progression, cultivation, and contracts

The confirmed progression target is survival → established operator → business empire. Automation is a reward for mastering recurring work, not a starting convenience.

For Nadia's introductory order, recommend replacing the three-transaction requirement with thirty cumulative units of time calc. One delivery or several should count equally. Show delivered/required/remaining quantities and provide an explicit supply action with payment visible. Completing this capacity demonstration continues into the existing vein-sale request.

Recurring contracts then give the established phase its main operational challenge: known quantities due on distinct days for predictable payment, competing with stock reserved for experiments and combat. Staff eventually fulfil selected contracts automatically according to reserve quantities, priorities, and spending limits. Successful routine work appears in the morning accounts; shortfalls require attention.

Cultivation's proposed direction is guaranteed modest progress plus a chance of additional progress, instead of an all-or-nothing maintenance action. The user liked some cultivation suggestions but did not select a final formula. Preserve this as a balance proposal for a bounded prototype, not an approved replacement formula.

### Combat direction

Prototype four actions:

| Action | Benefit | Exposure |
|---|---|---|
| Fast attack | Damage during short openings | Counter stance can punish it |
| Heavy attack | More damage; bypasses Counter | Dodge avoids it; repeated swings generate fatigue |
| Counter stance | Stops and retaliates against a selected opponent's fast attack | Heavy attacks break through |
| Dodge stance | Avoids a selected opponent's heavy attack | Does no damage; fast attacks can catch it |

Defending consumes the player's action; it is not a free additional input. Show the selected opponent and all other incoming threats. Announced enemy intent includes action, target, damage range where relevant, and resolution timing, and remains committed until resolved or visibly interrupted.

Prototype two heavy swings producing an Exhausted next turn, during which the attacker cannot act. A dodged heavy still causes fatigue. Apply the same rule to the player and enemies. Show two exertion marks. Exhaustion initially grants only the lost action, not an additional automatic critical hit. Two swings is a **prototype value**, originating from the user's example, not a final balance lock.

Start with dependable defensive matchups. Enemy combinations and target selection should provide uncertainty before adding random failure to a correctly chosen defence.

Enemy teaching sequence: brawler (Heavy/Dodge/exhaustion), knife fighter (Fast/Counter), enforcer (Counter and Heavy), then mixed squads. Existing planned Grab/Bolt and Call intents follow once the basic interaction is understandable. Avoid making “dodge twice, heavy, repeat” the universal optimal strategy.

Calc expands these rules: Shield answers additional exposure, Time Pearl delays an attacker, Enhancement Powder exploits openings, and area effects answer groups. Exact changes to existing effects require their own specified contracts. Keep ordinary enemies at fixed strength so later power is perceptible; stage selected multi-wave fights as late-game content rather than turning every routine encounter into a long battle.

## User Stories

1. As a player, I want the full time-of-day name visible, so that I understand my current phase immediately.
2. As a returning player, I want day and phase visible outside animations, so that I can resume without remembering a transition.
3. As a player, I want completed and remaining daily phases distinguishable without colour alone, so that I can plan my actions.
4. As a player, I want every time-consuming action to visibly advance the day, so that time feels consequential.
5. As a player, I want the transition to last only 1–2 seconds, so that it adds rhythm without dominating play.
6. As a player, I want a consistent non-skippable transition, so that the game has a deliberate daily cadence.
7. As a player, I want a London park and skyline to anchor that transition, so that the setting remains recognisable.
8. As a player, I want sun, moon, and shadows to communicate the phase change, so that the passage of time is intuitive.
9. As a player, I want early Rest to pass through night, so that I understand that I gave up the remaining day.
10. As a player, I want action outcomes communicated before transitions, so that I know what my action achieved.
11. As a player, I want free or blocked actions not to play time transitions, so that presentation matches actual cost.
12. As a player sensitive to motion, I want a reduced-motion presentation, so that the transition remains comfortable.
13. As a player, I want the final daily action labelled, so that overnight consequences do not surprise me.
14. As a player, I want a compact morning account, so that I understand what changed overnight.
15. As an established operator, I want staff output highlighted in that account, so that automation feels rewarding.
16. As a player, I want urgent warnings to remain on the board, so that routine updates cannot conceal an unresolved raid.
17. As a mobile player, I want the device to vibrate for a new urgent alarm, so that it feels like my in-game phone is calling for attention.
18. As a player, I want a visible phone vibration cue too, so that alarms remain legible without hardware haptics.
19. As a player, I want a vibration preference, so that I can control physical feedback.
20. As a player, I want alarms to open after my current interaction, so that a choice or attack is not interrupted.
21. As a player, I want an alarm to identify the vein, district, and deadline, so that I can make an informed response.
22. As a player, I want to enter defence from the alarm, so that I need not search through navigation.
23. As a player, I want non-intervention consequences explained, so that leaving a vein undefended is deliberate.
24. As a player, I want to defer an alarm without resolving it, so that I can inspect my preparation first.
25. As a player, I want multiple raids grouped, so that I can compare priorities without repeated pop-ups.
26. As a player, I want routine successes to remain quiet, so that urgent interruptions retain meaning.
27. As an early operator, I want useful progress from maintenance under the proposed cultivation model, so that scarce time is not repeatedly wasted.
28. As a player, I want guaranteed and bonus cultivation outcomes previewed separately, so that I understand the proposed risk.
29. As an early operator, I want Nadia's supply requirement to measure quantity, so that splitting a trade offers no artificial advantage.
30. As a supplier, I want partial deliveries and remaining quantities visible, so that I can plan production.
31. As a supplier, I want payment and quantity visible before delivery, so that fulfilment is an economic decision.
32. As an established operator, I want recurring contracts with explicit due dates, so that I can build dependable income.
33. As a player, I want contract commitments to compete with personal stock needs, so that production choices matter.
34. As an employer, I want to delegate selected contracts, so that established routines stop consuming my attention.
35. As an employer, I want reserve stock, priorities, and spending limits, so that staff follow my business strategy.
36. As an employer, I want shortfalls surfaced and successful routine deliveries summarised, so that I manage exceptions.
37. As a combatant, I want distinct fast and heavy attacks, so that attacking involves a tactical choice.
38. As a combatant, I want to Counter fast attacks, so that reading the opponent creates an opening.
39. As a combatant, I want Heavy to bypass Counter, so that defensive stances have an answer.
40. As a combatant, I want to Dodge heavy attacks, so that I can survive and exhaust a stronger opponent.
41. As a combatant, I want fatigue and exhaustion visible on both sides, so that I can plan openings and avoid overcommitting.
42. As a combatant, I want defence to cost my action, so that safety competes with dealing damage.
43. As a combatant, I want committed enemy intents and timing visible, so that my response is informed.
44. As a combatant facing a squad, I want to know which opponent my defence covers, so that remaining exposure is clear.
45. As a combatant, I want different enemy patterns, so that one repetitive sequence cannot solve every encounter.
46. As a prepared operator, I want calc to overcome ordinary tactical limits, so that business success becomes combat power.
47. As a powerful late-game player, I want old enemies to remain weak, so that progression is tangible.
48. As a late-game player, I want selected wave encounters, so that I can demonstrate sustained solo power.
49. As a player using Rewind, I want restored intent, fatigue, and stance state, so that undo remains trustworthy.
50. As a player loading a save, I want contracts and unresolved alarms preserved without duplicate payment or vibration, so that resuming is safe.

## Implementation Decisions

- Preserve one-way data flow. Content and tunable values belong in data; persistent gameplay state remains a pure data tree; systems own mutations; screens render and invoke systems. Device vibration, animation, and scene navigation presentation stay outside pure gameplay systems.
- Prefer existing TimeSystem action boundaries, Raiding pending-defence records, PhoneNav, Notify, Objectives, Rooms, Economy, Combat, Snapshots, and SaveManager over competing implementations of their responsibilities.
- Capture the time transition's source and destination at the authoritative time boundary. Present it at a safe completed-action boundary. Existing actions can advance time before their result has finished resolving; do not equate the current time-change signal with permission to display the overlay immediately.
- Initial scope preserves current daily-tick ordering and automatic rollover. Animation completion never charges time, reruns a tick, rolls raids, or determines rewards. One cost-bearing action yields one transition, including Rest.
- Block input through the overlay. Recovery after pause/reload must not replay gameplay effects or strand the player behind a transition.
- Reuse one panorama with simple composited layers. Do not reskin every district/HQ scene by time of day. Exact art, duration within 1–2 seconds, and sky/shadow motion are presentation tuning choices.
- Derive urgent phone presentation and pinned board entries from unresolved situations, not ephemeral notification strings. Use stable situation identity for deduplication. Group simultaneous arrivals; do not vibrate again on every render, navigation, or load.
- Haptic capability belongs behind a small presentation/platform adapter. Supported mobile hardware must physically vibrate; desktop/unsupported platforms remain functional. Platform API and export requirements must be verified against official documentation during implementation, not guessed from this spec.
- Phone alarms follow the existing phone visual family and app-icon contract. A new alarm app, if introduced, uses the same registry/icon loading convention. The dot-matrix board gains no buttons.
- Revalidate a raid when the player responds. A resolved, expired, or otherwise unavailable defence cannot be started from a stale alarm. Deferral does not extend its deadline. Existing raid/security/alarm eligibility remains unchanged.
- Distinguish presentation dismissal, deliberate non-intervention, and actual raid resolution. Exact early-abandonment timing must be specified before altering current pending-raid expiry behaviour.
- Contract fulfilment uses an explicit business operation shared by manual and staff execution. Store quantities, due periods, payments, and fulfilment identity as pure data; make settlement idempotent. Do not silently hijack unrelated trades.
- Nadia's proposed quantity-only introductory order retains thirty units and the subsequent vein-sale story. Preserve completed objectives in existing saves and prevent duplicate rewards. Decide how existing partial qualifying trades transfer before migration implementation.
- Staff automation builds on existing room/contact processing. Reserve stock, priority, affordability, and spending limits are gameplay policy; screens do not implement them. Contract and employee numbers remain to be authored.
- Combat retains the existing combatant array and turn-order foundation. Add committed intent, defence target/stance, exertion, and exhaustion as serializable state with snapshot coverage. Presentation consumes resolved combat beats rather than independently predicting outcomes.
- The four-action table is the prototype contract. Precise damage, fatigue reset, defence duration under speed ordering, interruption interactions, and multi-action effects must be resolved in the prototype specification before production combat changes.
- Do not silently implement earlier speculative economy changes. Property-based daily bills, arrears, guaranteed cultivation, earlier staff unlocks, and additional effect powers are recorded below as unresolved proposals.
- Update canonical mechanics, domain terminology/ADRs when applicable, and the ownership map alongside eventual implementation. This document alone does not rewrite canonical formulas.

## Testing Decisions

- Good tests assert player-visible results through public gameplay operations and rendered interaction boundaries, not private helper structure, exact node trees, or animation implementation details.
- Prefer the existing highest useful seam for each area: public time-consuming actions and TimeSystem, pending-raid response operations, objective/trade fulfilment, room/staff daily processing, and Combat action resolution. Do not create one artificial global facade for otherwise independent systems.
- Existing time-system tests establish three-block rollover and Rest; raid tests cover pending defence and outcomes; objective tests use synthetic content; room tests cover daily automation; combat and combat-screen/director tests cover action results and presentation; phone navigation/notification and save-manager tests provide integration precedent.
- Time acceptance: each paid action advances exactly once and presents one transition; free/blocked actions present none; all phase transitions and early Rest identify the correct destination; rollover effects remain once-only; action results precede overlays; underlying input is blocked for the full 1–2 seconds; there is no skip path.
- Alarm acceptance: newly actionable raid opens at a safe boundary; duplicate refreshes do not reopen/vibrate; simultaneous raids group; Defend uses the existing flow; Decide later/back retains urgency; expired alarms cannot dispatch defence; routine notifications cannot displace unresolved urgent warnings.
- Platform acceptance: adapter tests cover enabled/disabled/unsupported cases; physical-device QA confirms vibration actually occurs and settings suppress it. Headless tests cannot establish physical vibration or visual readability.
- Contract acceptance after rules are specified: one or multiple deliveries satisfy the same thirty-unit order; progress/payment are accurate; repeated settlement cannot double-pay; manual and automated paths enforce the same obligations; staff preserve reserves and budgets; missed deliveries create the specified exception; save/load preserves period identity.
- Cultivation prototype evaluation: compare time to stabilise the first vein, failed-feeling actions per day, available bill-paying opportunities, and pressure from a second vein. Do not assert an unapproved new formula in production tests.
- Combat prototype acceptance: Fast versus Counter; Heavy versus Counter; Heavy versus Dodge; Fast versus Dodge; two-heavy prototype exhaustion; a dodged Heavy still adds fatigue; exhaustion loses the specified action; defence consumes an action and covers its selected opponent; other opponents remain dangerous; committed intents persist unless interrupted; Rewind restores all new combat state.
- Balance evaluation: test early solo threats, mixed squads, and a late prepared build against the same early enemy. Assess whether one defensive cycle dominates, whether preparation visibly changes power, and whether waves remain readable on a portrait phone.
- Device QA: 390px portrait baseline and relevant safe areas; readable phase labels; panorama motion/shadows; reduced-motion treatment; alarm grouping; haptic feel; combat buttons and intent targets; no tap-through on auto-open or transition boundaries.
- Follow repository syntax checks immediately after each future GDScript edit, then the full headless suite and acceptance checks. No gameplay tests are claimed run for this documentation-only synthesis.
- Test-seam confirmation: present this proposed division to the user after publishing the spec, as required by the invoked skill. Their response can refine the test plan without losing the completed synthesis.

## Out of Scope

- Implementing game changes, creating final art, or balancing numbers during this write-up.
- Separate time-of-day artwork for every game screen; an animation skip control; a real-time day/night clock.
- Action buttons embedded in the dot-matrix board.
- Background push notifications or automatic phone interruptions during unresolved choices/combat.
- A new manually committed day-end state without an explicit follow-up rule decision.
- Automatically treating every recommendation in the earlier review as approved: refinement previews, HQ art progression, debug-control removal, arrears, and property-cost changes remain separate candidates.
- Final contract pricing, cadence, failure penalties, employee capacity/wages/unlock tiers, and combat damage/fatigue balance.
- Replacing the entire combat system or changing existing calc powers before interaction rules are specified.

## Further Notes

### Decision strength

- Explicit latest requirements: non-skippable 1–2 second time animation; actual device vibration as an alarm feature.
- Confirmed direction: a reusable time panorama; phone-based actionable alarms; persistent urgent warnings; recurring contracts becoming staff-automated; progression from financial/combat struggle to a city-scale business and solo wave-clearing power.
- Combat direction discussed: Fast/Heavy/Counter/Dodge and fatigue openings. Two swings, deterministic matchups, single-target defence, and exact enemy patterns are prototype recommendations; final balance is not yet settled.
- Cultivation: partial interest only. Guaranteed baseline plus bonus growth remains a proposal, not a selected formula.

### Decisions to settle through bounded follow-up work

1. Cultivation: select whether guaranteed progress is desired, then set baseline/bonus growth and XP while respecting drift and the three-block budget.
2. Bills: **settled 2026-09-23** in [docs/adr/0006-property-bills-and-arrears.md](../../docs/adr/0006-property-bills-and-arrears.md). It covers rent-or-buy tenure, arrears with 5%/day compounding interest from day 6 and a forced downgrade at day 10, and a James-job-only recovery route. Production is unchanged; implementation needs a separately scoped ticket.
3. Contracts: set initial catalogue, quantity/payment/cadence/deadlines, partial-delivery policy, missed-order consequences, staff unlock/capacity/cost, and exact daily processing order relative to production, raids, and settlement.
4. Nadia migration: map existing partial trade progress into the explicit supply order without taking rewards away or granting them twice.
5. Alarms: **settled 2026-09-13.** “Leave undefended” resolves the selected raid immediately after confirmation, using the normal guard-repel check and otherwise its already-rolled outcome. Closing/back remains deferral; current expiry timing otherwise remains unchanged.
6. Combat: define fatigue reset/recovery, whether consecutive swings are required, stance timing versus fast opponents, multiple strikes and multiple targets, freezes/exhaustion overlap, stance expiry if its target dies, and available actions during exhaustion.
7. Combat economy: establish a baseline combat action/resource budget so free item uses or extra attacks do not bypass the intended stance/exhaustion decisions.

### Delivery order

Deliver time presentation and actionable alarm presentation first; they can use existing gameplay rules. Then specify the quantity-only introductory order and recurring contract/staff lifecycle. Prototype combat independently before production integration. Resolve cultivation and bill changes separately; they are not dependencies of the presentation work.

## Contract and staff specification

See [business-spec.md](business-spec.md). It is the canonical specification
for ticket 10; its open decisions are not implementation authority.


### Review and provenance

Written from the 2026-09-13 conversation and inspected current systems, screens, data, tests, domain glossary, phone icon ADR, and design documents. Current code and older vision prose diverge in several areas, including free travel, squad combat already existing, cultivation numbers, and bills; use canonical reference plus explicit approved amendments when implementing, never old prose as an accidental mechanics source.

No prototype was built in this session. No numeric recommendation here is represented as measured balance evidence. The earlier runtime attempt used installed Godot 4.4.1 and failed opening a log; it does not validate the 4.7 target or the visual experience.

PROSE-REVIEW: phase/action/alarm labels in this spec are proposed UI copy, not final authored dialogue.
