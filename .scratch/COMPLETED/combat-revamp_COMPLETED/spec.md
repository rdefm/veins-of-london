# Combat revamp — Open/Guarded round planning (prototype)

Status: ready-for-agent

## Problem Statement

Combat today is "press Attack until someone falls over". Enemy intent is never shown (the UI always says "Intent: Attacking"), so there is nothing to read and nothing to answer. Prophet's Breath is a small evade buff with no tactical use. Consumables are stat food rather than answers. The 2026-10-09 review named the missing intent system as the single largest gap between the game and its vision, and the main reason combat isn't fun.

The player wants Guy Ritchie's Sherlock Holmes: read the opponent, plan the whole exchange in your head, then watch it play out. Waiting behind your guard for an opening, or making one, should beat swinging blindly. Calc items should be the ace in the hole that turns a hard fight, or a fight against several people, into a win. They can't be spammed, so loadout choice and item tier matter.

Nobody yet knows the right fight length, action counts or damage scale, so the system has to be prototyped and tuned before it replaces live combat.

## Solution

A sandboxed **Combat Prototype** in the Debug app. It replaces the existing Fast/Heavy/Counter/Dodge prototype and implements a round-planning combat model:

- Every combatant is either **Open** or **Guarded** (its **guard state**). A hit on an Open combatant does full damage; a hit on a Guarded one does chip damage.
- A combatant's guard state is set by its **last action**. Guard makes you Guarded. Strike makes you Open. Some moves leave it unchanged. Guard state carries across rounds.
- Each round, every enemy **commits its round plan up front**. The plan is shown as intent icons on a shared timeline. Allies (AI) commit theirs, also shown. The round then resolves action by action in timeline order and **pauses at each of the player's actions** (per-action decisions, as in live combat): the player picks one move or item and target with the actual state in front of them, it resolves, and play runs on to their next action or the round's end. The screen plays back each step's beats.
- **Openings** come two ways: an enemy turns Open by attacking (punish it next), or you force one with Feint, or Lure an attacker into overcommitting.
- **Stun** is a move, but limited: it only lands on an Open target and takes one action from one target. Items (Time Pearl, Black Hole) stun harder, ignore guard and hit every enemy. A skilled fighter stays formidable 1v1, but items are what win against groups.
- **Combat Skill level** sets actions per round (2, rising to 3 at level 3), speed, attack, HP and crit chance. The prototype setup has level selectors for the player, the enemies and the allies, so the curve can be tested.
- Crits: a low chance (rising slightly with Combat Skill) for double damage. **Be a Lady** makes the user's rolls max and raises their crit chance to 1 in 3.
- **Prophet's Breath** becomes sight: it reveals enemy targets, damage and next round's plans.
- **Leg it** is a move. Once it resolves, the fleer's remaining actions that round are lost. Guarding until your last action and then legging it is a legitimate way to escape while taking as little damage as possible.
- A headless balance sim plays many prototype fights to measure fight length, win rate and HP left. That answers "ideal fight length" with data.

## User Stories

### Setup
1. As a designer, I want a Combat Prototype card in the Debug app, so that I can launch the prototype without touching live combat.
2. As a designer, I want to pick the player's Combat Skill level (1–5), so that I can feel how each level plays.
3. As a designer, I want to pick each enemy's archetype (Mugger, Bruiser, Turtle) and count (1–3), so that I can test 1v1 and group fights.
4. As a designer, I want to pick the enemies' combat level, so that I can test mismatched and matched fights.
5. As a designer, I want to add 0–2 AI allies with their own combat level, so that I can test squad play.
6. As a designer, I want to fill the player's two loadout slots with any prototype item at any tier, so that I can test item impact without crafting stock.
7. As a designer, I want the prototype to never touch my real HP, inventory, Dial or save progress, so that testing is free and safe.

### Reading the round
8. As a player, I want every combatant's guard state shown at all times, so that I know who can be hurt properly right now.
9. As a player, I want each enemy's committed actions shown as intent icons on the round timeline, so that I can plan answers.
10. As a player, I want the timeline to order every action (mine, allies', enemies') by action index and then speed, so that I can see exactly which of my actions lands before or after each enemy action.
11. As a player, I want to see my allies' planned actions before I commit, so that I can sync with them (e.g. they Feint, I Strike).
12. As a player without Prophet's Breath, I want to see only each enemy action's type, so that reading the fight is a skill and sight is worth buying.
13. As a player using Prophet's Breath, I want to see each enemy action's target and damage range, plus the enemies' plans for next round, so that I can plan two rounds ahead.
14. As a player, I want to see a preview of my guard state over the round as I place actions, so that I can tell whether I'll end the round exposed.

### Planning
15. As a player, I want to fill each of my action positions this round from a move list, so that I plan the whole round before anything happens.
16. As a player, I want Guard to make me Guarded until my next action, so that I can wait out an enemy's attack taking only chip damage.
17. As a player, I want Strike to deal my attack damage to my chosen target and leave me Open, so that attacking always has a cost.
18. As a player, I want Feint to make a Guarded target Open until its next Guard, without changing my own guard state, so that I can make an opening on a turtling enemy.
19. As a player, I want Stun to remove an Open target's next action, so that I can interrupt it and extend its opening.
20. As a player, I want Stun to fail with no effect on a Guarded target, so that I have to set it up (Feint, or wait for them to attack) and can't stun-lock anyone.
21. As a player, I want Lure (a two-action guard) to keep me Guarded and make the first enemy who attacks me while it's active Exposed (Open regardless of its own actions, for a set duration), so that I can bait a big opening.
22. As a player, I want Lure to end after the first attack it catches, leaving me Open, so that baiting several attackers has a price.
23. As a player, I want Leg it as a move that ends my round on resolution, so that I can guard first and flee on my last action.
24. As a player, I want to pick a target per action (enemy for Strike/Feint/Stun, ally or self for heals), so that I can focus enemies down.
25. As a player, I want an action aimed at an enemy KO'd earlier in the round to retarget the next living enemy, so that one early kill doesn't waste the rest of my plan.
26. As a player, I want using an item or casting a Dial Complication to take one action and keep my guard state, so that items fit the plan without being free.
27. As a player, I want a clear Commit button that locks my plan and plays the round, so that planning and watching are distinct phases.
28. As a player, I want to change any planned action before committing, so that planning is low-friction on a phone.

### Resolution
29. As a player, I want damage to roll within the attacker's range, so that luck matters and Be a Lady has something to fix.
30. As a player, I want hits on Guarded targets to deal chip damage (draft ×0.25), so that guarding is strong but not total.
31. As a player, I want a small chance (rising with Combat Skill) to crit for double damage, so that fights have spikes.
32. As a player, I want a crit on a Guarded target to deal double chip, not pierce guard, so that Guard stays the core defence.
33. As a player, I want a combatant KO'd mid-round to lose its remaining actions, so that killing something before it acts actually stops it.
34. As a player, I want the fight to end at once when all enemies are KO'd, I'm KO'd, or I successfully Leg it, so that outcomes are crisp.
35. As a player, I want a failed Leg it to leave me Open and lose my remaining actions, so that fleeing carries risk.
36. As a player, I want each resolved action played back beat by beat (hit, chip, crit, guard change, stun, flee), so that I can see why the plan worked or didn't.
37. As a player, I want to Rewind to the start of the round I just committed, with the plan editable again, so that I can try a different answer to the same intents.

### Combat Skill and levels
38. As a player, I want 2 actions per round at Combat Skill 1–2 and 3 at level 3+, so that levelling up visibly changes how I fight.
39. As a player, I want my 3rd action to land after everyone's 2nd action, so that a faster, higher-level fighter gets the last word in a round.
40. As a designer, I want actions-per-round, speed, attack, HP, crit chance and chip multiplier as data curves, so that I can retune without code.
41. As a designer, I want enemies and allies in the prototype to use the same combat-level curves as the player, plus a per-archetype base, so that a matched fight is a fair mirror.

### Enemies and allies
42. As a player, I want a Mugger that mixes Strike and Guard, so that I learn the basic read-and-punish rhythm.
43. As a player, I want a Bruiser that strikes a lot, so that I learn to guard and punish natural openings.
44. As a player, I want a Turtle that guards a lot, so that I learn to Feint and Stun to make openings.
45. As a player, I want enemies to pick an attack target (me or an ally) when they commit their plan, so that Prophet's Breath has a target to reveal.
46. As a player, I want allies to plan their own actions by reading the visible enemy intents (guard against incoming strikes, strike Open enemies, feint turtles), so that they behave like competent fighters.
47. As a player, I want allies to use their own two loadout slots by simple rules, so that squad item play exists without me micromanaging.

### Items (the ace in the hole)
48. As a player, I want only my two loadout slots usable per fight, so that I can't spam items to win.
49. As a player, I want item strength read at the unit's tier, so that high-tier stock is worth crafting.
50. As a player, I want Time Pearl to take actions from every enemy (count from tier) and leave them Open, regardless of guard, so that it outclasses the Stun move against groups.
51. As a player, I want Black Hole to deal damage to every enemy, ignoring guard, and take actions from all of them, so that it's the big group answer.
52. As a player, I want Blast to deal damage that ignores guard, so that I can hurt a turtle without an opening.
53. As a player, I want Shield to hold me Guarded (even while I Strike) while its absorb pool lasts, so that I can attack safely for a while.
54. As a player, I want Enhancement Powder to give me +1 action per round for a number of rounds set by tier, starting the round I use it, so that I can out-tempo enemies straight away.
54a. As a player, I want placing Enhancement Powder in my plan to open an extra action position at the end of my plan this round, so that I can plan the bonus action before committing.
55. As a player, I want Prophet's Breath to grant sight for a number of rounds set by tier, so that I can plan ahead.
56. As a player, I want Be a Lady to give me max damage rolls and a 1-in-3 crit chance for a number of rounds set by tier, so that luck is mine to buy.
57. As a player, I want Healing Burst to heal me or an ally, so that sustain costs an action and a slot.
58. As a player, I want an item's effect to start at the moment its action resolves on the timeline, so that item timing is part of the plan.

### Balance sim
59. As a designer, I want a headless sim that plays N fights per matchup (player level × enemy archetype/count/level × loadout), so that I can measure average rounds, win rate, HP left and actions planned.
60. As a designer, I want the sim to run at least two player policies, naive (always Strike) and reader (guards incoming strikes, strikes openings, feints turtles), so that I can confirm reading the intents clearly beats button-mashing.
61. As a designer, I want the sim seeded and reproducible, so that a balance change can be compared run to run.

## Implementation Decisions

- **Replaces the existing combat prototype.** The Fast/Heavy/Counter/Dodge prototype system, screen, data table, its GameData validation, its SaveManager int-type restore, and its tests are removed and replaced. The `combatPrototype` state key and the Debug-app launcher slot are reused. CODEMAP updated in the same commit.
- **Fully sandboxed** (lab-revamp bench prototype precedent). Own state at `GameState.state["combatPrototype"]` (pure data), own snapshot stack (the existing `combatPrototype` Snapshots key, cap 2), own screen. Items come from a sandbox loadout picked at setup, not from real inventory. Never touches the player's real hp, inventory, Dial, XP or calendar. Live combat (`Combat`, REFERENCE §3.7/§3.7a) is untouched.
- **One system module, one test seam.** The prototype system exposes two public entry points that tests, the sim and the screen all use:
  - `start(config) -> state`: config = player level, enemy list (archetype + level), ally list (level), player loadout (2 × recipe+tier), seed. Builds the fight, pre-rolls enemy plans for round 1 and round 2 (so Prophet's Breath can reveal the next round), then resolves up to the player's first action.
  - `choose_move(move, target)` / `choose_item(slot, target) -> result` (**per-action decisions**): the player's pick at the paused position. Allies' and enemies' plans are already committed in state. The pick resolves, then the timeline resolves on from a resumable cursor in `combatPrototype` state (pure data, like live combat's `turnCursor`) to the player's next action or the fight's end, rolling the following round's enemy and ally plans at each round boundary. Returns that step's ordered beats plus the outcome (null / win / loss / fled). A multi-action move (Lure) takes the current and next player positions from one pick; Enhancement Powder's extra position is a further pause in the same round. A player position lost to Stun/freeze, or after a Leg it, plays without a pause. Only targets living at the pause are offered.
  - Read-only helpers the screen needs (timeline ordering, guard-state preview, block reasons for an invalid plan) are pure functions over state and are covered through the two entry points' outcomes, not tested separately.
  - Rewind restores the snapshot taken at the last decision point (**rewind-to-last-pick**), with that pick undone and replayable; a second Rewind steps one more pick back (snapshot cap 2), across a round boundary restoring that round's pre-rolled plans.
- **Vocabulary.** "Stance" is already a faction term in CONTEXT.md, so this system uses **guard state** (values `open` / `guarded`). An **action** is one entry in a combatant's round plan (a move, an item use or a Dial cast). A **round plan** is a combatant's ordered actions for one round. **Exposed** is a forced-Open status with a duration that the target's own Guard can't clear.
- **Timeline order.** All actions in a round sort by action index (1st, 2nd, 3rd), then speed descending, then the existing tie-break (player > allies > enemies, then array order). Everyone's 1st actions resolve, then everyone's 2nd, then any 3rd.
- **Guard-state rule.** Each move declares its effect on the actor's guard state: `guarded`, `open` or `unchanged`. Fight start: everyone Guarded. Items and Dial casts are `unchanged` (except Shield's override, below).
- **Moves as data** (new prototype data table). Each row: id, display name, action cost (1, or 2 for Lure), actor guard effect, target type, effect (damage / open / stun / lure / flee), effect parameters, condition (e.g. Stun requires target Open), and a level field reserved for later move levels. Prototype moves:

  | id | Cost | Actor after | Effect |
  |---|---|---|---|
  | guard | 1 | guarded | — |
  | strike | 1 | open | Damage roll vs target (full if Open, ×chip if Guarded) |
  | feint | 1 | unchanged | Guarded target → Open until its next Guard; no-op on an Open target |
  | stun | 1 | open | Requires Open target, else fizzles; removes target's next 1 action |
  | lure | 2 | guarded | First enemy to attack the actor while Lure is active becomes Exposed (draft: through the end of next round); Lure then ends and the actor is Open |
  | legIt | 1 | open | Flee roll (draft: existing 0.65); success ends fight `fled`; either way the actor's remaining actions this round are lost |

- **Damage.** Roll within the attacker's range (Combat Skill attack curve + archetype base). Target Open → full; Guarded → `round(dmg × chipMultiplier)` (draft 0.25, min 1). Crit doubles the final figure (a Guarded crit = 2× chip). An Exposed target counts as Open. Shield absorb pool drains 1:1 before HP.
- **Crit chance** is a per-Combat-Skill-level data curve (draft: low single-digit %, rising slightly). Be a Lady active: roll = attacker's max, crit chance = 1/3.
- **Actions per round** is a per-level data curve, draft `[_, 2, 2, 3, 3, 3]`. Enhancement Powder adds +1 for its duration. Speed reuses the Combat Skill speed curve. HP and attack reuse the Combat Skill HP/attack curves on top of an archetype base. All combatants (player, allies, enemies) use the same curves in the prototype.
- **Enemy plans** are committed at round start from weighted plan patterns per archetype (data), with a target per offensive action (uniform over player + living allies). Enemies never adapt mid-round. Mugger: mixed. Bruiser: strike-heavy. Turtle: guard-heavy with occasional strikes.
- **Ally AI** plans after the enemy plans are rolled, reading them: Guard on the index where an enemy strikes it, Strike enemies who will be Open, Feint a Guarded enemy ahead of a teammate's Strike, uses its 2 loadout items by simple rules (heal below 40%, Time Pearl/Black Hole vs 2+ enemies). Ally plans are visible to the player before commit.
- **Stun and freeze removal.** A removed action is dropped from the timeline. The target's guard state stays as it was. Removal from Time Pearl/Black Hole ignores guard and the Open condition.
- **Prototype item effects** (power from each recipe's existing `effectPower` at the unit's tier):

  | Item | Effect |
  |---|---|
  | timePearl | Every living enemy loses its next `power` actions and is Open while frozen |
  | blackHole | `power` damage to every living enemy, ignores guard; each loses `1 + floor(power/8)` actions |
  | blast | `power` damage to target, ignores guard |
  | shield | Actor gets an absorb pool of `power`; while it's > 0 the actor counts as Guarded regardless of its own moves |
  | enhancementPowder | +1 action per round for `power ≥ 3 ? 2 : 1` rounds, starting this round: the extra action is appended as the user's next action index (ordered with that index's other actions by speed), and the current round counts toward the duration. If Powder is the user's last planned action, the extra one follows it. |
  | prophetsBreath | Sight for `power` rounds, starting immediately (this round's targets/damage, next round's plans) |
  | beALady | Max rolls + 1/3 crit for `power` rounds, starting immediately |
  | healingBurst | Heal self or ally by `power`, capped at hpMax |

  Dial casts in the prototype: out of scope (see below).
- **KO and outcome.** A KO'd combatant's remaining actions are dropped. An action aimed at a KO'd enemy retargets the next living enemy (index order); a heal aimed at a KO'd ally fizzles. Win = all enemies KO'd; loss = player KO'd (no Failsafe, no ally-carried fight in the prototype); fled = successful Leg it.
- **Screen.** The prototype screen shows:
  - **Setup panel:** level selectors, archetype/count, allies, loadout picker.
  - **Planning timeline**, reusing the turn-strip idea: one lane of interleaved positions; enemy and ally actions pre-filled as icons; the player's empty positions filled from the move/item palette; per-combatant guard-state bar previewing the round.
  - A pick at each pause, then that step's beat playback, then **Rewind**.
  - The screen calls only the system's entry points and helpers; it never mutates state.
- **Balance sim** is a headless script driving only `start`/`choose_move`/`choose_item`, with the naive and reader policies as a decision callback at each pause, over a matchup grid. It prints a summary table (rounds mean/p90, win %, HP left %, actions planned).
- **Data validation** for the new table runs at boot in GameData (moves, archetypes, plan patterns and curves are well-formed; every pattern's move ids exist).

## Testing Decisions

- Good tests here assert what a player would observe after each pick (`choose_move`/`choose_item`): HP, guard states, removed actions, outcome, beat order. They never assert private helpers or intermediate structures. The fight is seeded, so every test is deterministic.
- Tested module: the new prototype system only, through `start` + `choose_move`/`choose_item` (tests script plans for player, enemies and allies by setting up the committed enemy/ally plans via a seeded config or a test-only plan override in `config`).
- Key cases:
  - Guard then Strike vs an enemy that Strikes then Guards: player takes chip, enemy takes full.
  - Strike into a Guarded target: chip.
  - Ending a round on Strike: the player is Open at the next round's start and takes full from a faster enemy's first Strike.
  - Feint then Strike on a Turtle: full damage. Feint on an Open target: no-op.
  - Stun on Guarded: fizzles. Stun on Open: the target's next action is removed and it stays Open.
  - Lure: the first attacker becomes Exposed (its Guard doesn't restore guard); the second attacker hits an Open player.
  - Leg it as last action after Guards: no full hits taken that round; success = `fled`; failure = Open, no further actions.
  - Level 3 player: 3 actions, the 3rd ordered after all 2nd actions.
  - Crit: forced via seed → double; on Guarded → double chip. Be a Lady → max roll.
  - Time Pearl removes actions from every enemy, ignoring guard. Black Hole ignores guard on all. Shield holds the striker Guarded until drained. Powder adds an action this round (resolved after the Powder action) and, at power ≥ 3, next round too.
  - Prophet's Breath: the next round's enemy plans are present in the result/state when sight is active (and hidden from the screen-facing helper otherwise).
  - KO mid-round drops remaining actions. Retarget after an early kill.
  - Rewind restores the pre-commit state, including the pre-rolled plans.
  - The real player's hp/inventory are unchanged after a full prototype fight.
- Prior art: the current combat-prototype tests (the deterministic seeded-fight pattern, which these replace) and the bench-prototype sandbox tests for sandbox isolation.
- The sim is not a test; it's a tool. Acceptance: it runs headless to completion and shows the reader policy beating the naive one in matched fights.

## Out of Scope

- Changing live combat (`Combat`, the combat screen, REFERENCE §3.7/§3.7a) or the save schema beyond the prototype's own key. Porting to live combat follows after tuning, as a separate spec.
- Move learning (observe, trainers) and move levels / named level variants (e.g. Slap → Box the Ears). The data shape reserves a level field only.
- Combat openers (Talk / Bribe / Intimidate, VISION Layer 1).
- Dial casts, Failsafe, Rewind-as-consumable, Wormhole, Pan's family and other calc not listed above.
- Reinforcement queues, more than 3 per side, guard kits, raider kits.
- Final art, animation polish and pixel stage; the prototype screen can be plain.
- Final move/intent display names and flavour lines (drafted, PROSE-REVIEW).
- Deciding the ideal fight length (the sim produces the data; the decision comes after).

## Further Notes

- **Draft values needing tuning:** chip ×0.25; crit curve; actions curve `[_,2,2,3,3,3]`; Lure Exposed duration; Leg it chance 0.65; archetype bases and plan weights.
- **Defaults assumed, flag if wrong:**
  - Fight starts with everyone Guarded.
  - Stun leaves the actor Open (it's a hit).
  - Lure's Exposed lasts through the end of next round.
  - A failed Leg it leaves you Open.
  - Prophet's Breath and Be a Lady start the moment they resolve.
- **CONTEXT.md** should gain Guard state, Open/Guarded, Exposed, Action and Round plan entries once this design is approved. Not added yet.
- **Prophet's Breath rework** (evade → sight) and Be a Lady's combat role apply only inside the prototype until the port spec lands. REFERENCE.md is unchanged by this work.
- New prose (move names, intent lines, beat log lines) must be flagged `PROSE-REVIEW:` in the task report.
