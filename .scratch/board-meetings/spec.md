# Board Meetings — weekly goals (spec)

Status: ready-for-agent

Source vision: `docs/biz-meetings-vision.md`. This spec settles the open rules it lists for slice 1 and defines the slicing plan for the rest. Where this spec and the vision disagree, this spec wins; where this spec is silent, the vision is the brief and the gap is an open question for the human, not a guess.

## Problem Statement

After Business Empire Act 1 the player has a working business and a lot of systems pulling at them — offers, contracts, favours, partner asks, the Ticker, demand spikes, the Today card — and none of them says *what to aim for*. The Act 2 systems (market sim, shares, rivalry, guard upkeep) are built, but the Act 2 questline that was meant to introduce them is not, so the player arrives in a richer simulation with no direction through it. Separately, goals and quest progress are tracked through one mechanism (objectives → ToDo app → Today Story row), and any new goal system that invents a second tracker would split the player's "what am I doing" view in two.

## Solution

Once a week, on Monday, the founders — the player, Archie, James, with Owen always present — hold a short, funny board meeting. It reads last week's result (Minutes), pitches three goal cards from three different voices (Agenda), and closes with one-line asides (Any Other Business). The player picks one goal for the week. Every card's premise is true in the simulation, its numbers scale to the player's own business, it pays something even on a partial result, and not picking a card costs nothing.

Board Meetings **replace** the unbuilt Act 2 questline: the Act 2 beats become early ladder rungs, the first two pinned into the agenda until taken. The chosen goal becomes an objective instance tracked by the existing objectives evaluator and shown in the ToDo app (new "Board" section) and the Today card Story row — one tracker, not two.

The meeting is presented through the existing event system: a normal event whose Agenda is a hub of three generated options. A later "whiteboard" UI will replace only the pick step and act as the mid-week goal view; it is explicitly deferred (see Further Notes).

The system is built in **ladder slices** so mechanics and structure can be playtested and adjusted before every ladder's content is written. Slice 1 is the framework plus one ladder per voice.

## User Stories

### Meeting cadence and flow

1. As a player who has finished Business Empire Act 1, I want my first board meeting on the first Monday after Act 1 closes, so that Act 1's ending breathes and the new system arrives at a natural weekly boundary.
2. As a player, I want the first meeting (Week 1) to be a scripted beat that explains what the meetings are, so that I'm handed into the system rather than dropped into it.
3. As a player, I want a meeting every Monday after that, alongside payday and contract renewal, so that the week has a rhythm.
4. As a player, I want the meeting not to cost a time block, so that direction-setting never competes with doing.
5. As a player, I want the meeting to be short (roughly 30–60 seconds), so that it stays a treat and not a chore.
6. As a player, I want the meeting to open with Minutes reporting last week's result, so that I get closure on what I chose.
7. As a player, I want the pitcher of last week's goal to react to the result — celebrating full success, affectionately ribbing a base-tier-only result, laughing off a miss with "next week, then" — so that results feel human.
8. As a player, I want an Agenda of three goal cards, each pitched by a different voice, so that I have a real choice of direction.
9. As a player, I want an Any Other Business slot of light one-line asides and running gags, so that the meeting has personality beyond the cards.
10. As a player, I want the meeting set in James's workshop, so that the scene matches where the business actually lives right now.
11. As a player, I want the meeting to be able to start from wherever I am on Monday morning without travel, so that it never blocks my day.
12. As a player, I want urgent things (raid warnings, vein alarms, unpaid wages) to keep reaching me live and never wait for Monday, so that the meeting never hides a threat.

### Choosing and skipping

13. As a player, I want to choose exactly one goal per week, so that I have one legible ambition.
14. As a player, I want picking one card to cost nothing on the others, so that no choice is a punishment.
15. As a player, I want an unpicked voice to simply say "next week, then", so that nobody is upset with me.
16. As a player, I want voices I didn't pick to be a bit more likely to pitch next week, so that every character's goals keep coming round.
17. As a player, I want picking a voice's goal to raise my relation with that character a little, so that my choices quietly build relationships.
18. As a player, I want not picking a voice to never lower my relation with them, so that I never feel punished for choosing.
19. As a player, I want to be able to leave the meeting without choosing, so that I'm never trapped in a scene.
20. As a player who leaves without choosing, I want Archie to pick his own card for me ("You weren't there, so you're doing mine."), so that I always have a goal and the skip is a joke, not a penalty.
21. As a player, I want to always have exactly one active board goal after a meeting, so that the Story row and ToDo are never empty mid-week.

### Goal cards

22. As a player, I want each card to name who's pitching it, so that I know whose ambition I'm taking on.
23. As a player, I want each card to carry one spoken pitch line in the pitcher's voice, so that the choice feels like a conversation.
24. As a player, I want each card to show a "why this week" line pointing at something real (a Ticker headline, a demand spike, a faction relation, my own numbers), so that I trust the premise.
25. As a player, I want every card's premise to be true in the current game state, so that if Archie says the market wants fate ore, the market actually does.
26. As a player, I want each card to show base, target and stretch tiers with concrete numbers, so that I know what success looks like.
27. As a player, I want each card to preview the reward for each tier before I choose, so that I can weigh the options.
28. As a player, I want a short goal label (about 25 characters) for each card, so that the ToDo row and later the whiteboard can show it compactly.
29. As a player, I want goals to last one week by default, so that the rhythm stays weekly.
30. As a player, I want tier numbers to scale to my own business (recent stats), so that goals never go trivial or impossible as I grow.
31. As a player, I want the base tier to always pay something, so that partial success still feels good.
32. As a player, I want the stretch tier to pay extra, so that pushing hard is worth it.
33. As a player, I want to see the same three cards if I Rewind to Monday, so that Rewind can't be used to reroll the agenda.
34. As a player who Rewinds to Monday, I want to be able to choose a different card than before, so that Rewind still lets me change my mind.
35. As a player, I want occasionally (no more than about one week in five) two pitches to compete for the same thing as a flavour beat, so that the meeting has some playful tension that is never a trap.

### Progress and resolution

36. As a player, I want my chosen goal to appear in the ToDo app in a "Board" section with its progress, so that I can check it anytime.
37. As a player, I want the Today card Story row to show my current board goal and progress, so that my weekly ambition is always one glance away.
38. As a player, I want progress to show which tier I've reached so far, so that I know how close I am.
39. As a player, I want the stretch tier to lock in the moment I hit it mid-week, so that a later dip doesn't take away a result I earned.
40. As a player, I want the goal judged at the next Monday meeting, so that results land in the Minutes with a reaction.
41. As a player, I want the reward for the tier I reached paid at that meeting, so that the payoff is part of the scene.
42. As a player who missed even the base tier, I want no penalty beyond no reward, so that a missed goal is a shrug, not a setback.
43. As a player, I want a record of past goals and results kept in my save, so that Minutes and future memory lines can reference my history.

### Ladders (all v1, delivered in slices)

44. As a player, I want goal families to be ladders where a card offers the next rung I qualify for, so that goals follow where my business stands.
45. As a player, I want a rung I've already achieved without taking the goal to be skipped, so that I'm never asked to do what I've already done.
46. As a player, I want a ladder's rungs to open from real state rather than from finishing earlier rungs, so that nobody feels railroaded.
47. As a player, I want an Archie Market share ladder (x% of one ore's production → higher % → market leader → a second ore at x%), so that I can build dominance in a lane.
48. As a player, I want a James Financial ladder (reserve covers n weeks of real expenses → margin target → expansion fund), so that money discipline is a goal with a reward.
49. As a player, I want an Owen Cultivation ladder (yield target → bring a new vein online → vein health streak → cultivate a second ore type), so that Owen has his own nervous little ambitions.
50. As a player, I want Owen to pitch only occasionally and only cultivation rungs, so that his presence stays a gag rather than a third full voice.
51. As a player, when Owen has no rung to pitch, I want Archie to take his slot, so that there are always three cards.
52. As a player, I want a James Crafting ladder (crafting share of an item → new recipe tier → quality streak → signature item), so that a crafting empire is a supported route.
53. As a player, I want an Archie Landmark deals ladder where reaching a rung unlocks a specific, authored, recurring contract, so that I can build steady near-passive weekly income through the meetings.
54. As a player, I want landmark contracts to be scripted (buyer, volume, pay, term per rung), so that the number of high-paying recurring contracts I can hold is controlled.
55. As a player, I want an Office ladder starting with "Get a proper office", so that the meeting venue can move to my HQ as a reward.
56. As a player, I want a Partner ladder that spots a real synergy with a faction ("They burn half the fate ore in Camden. We make half the fate ore in Camden.") and asks me to raise the relationship, so that alliances have a reason.
57. As a player, I want a Defuse ladder that spots a coming clash with a faction and asks me to get ahead of it, so that I can head off aggression proactively.
58. As a player, I want Partner and Defuse to come from one overlap detector (veins in their district, crafting what they produce, producing what they consume, share approaching provocation), so that they read as two framings of the same truth.
59. As a player, I want a Security ladder (alarms → upgraded security → guards → guard kits) whose premise is real exposure (veins worth more than they're protected for, rising rival aggression), so that security is an opportunity, not a chore.

### Act 2 spine

60. As a player, I want the Act 2 beats delivered as meeting rungs rather than a separate questline, so that there's one direction system after Act 1.
61. As a player, I want a pinned card to reach a target share (about 25%) in one ore type, with James tipping which types are contested, so that I pick my lane.
62. As a player, I want, once the share beat is done, a pinned card to sign a 4-week supplier contract with a faction that crafts with that ore, so that I learn dependence.
63. As a player, I want a pinned card to keep appearing each week until I take it, while the other two slots stay free, so that the story advances on my terms.
64. As a player, I want to be able to pass on a pinned card in any given week, so that the spine never overrides "the player chooses".
65. As a player, after the first two beats, I want the rival's first move, the weather-or-soften response, reaching Partner, and the debrief to be achievable in any order and week, so that the rest of Act 2 fits my own play.
66. As a player, I want the rival's first visible move (once I pass the share threshold) to arrive live with a text explaining relation levers, so that I learn escalation and counters when it happens.
67. As a player, I want to weather that move (keep guards paid, lose no vein for N days) or soften it (spend on a relation action with the rival), so that I play my own way.
68. As a player, I want a closing debrief that marks Act 2 complete once all its beats are done, while the meetings carry on, so that the systems outlive the story.
69. As a player, I want Act 2 progress shown in the ToDo app like Act 1, so that I always know my next story step.

### Rewards

70. As a player, I want slice 1 rewards to be cash, consumables (`timePearl`, `enhancementPowder`), faction relation and short story vignettes, so that early rewards are varied without needing systems that don't exist yet.
71. As a player, I want each voice's rewards to lean towards its personality, so that whose goal I take shapes what I get.
72. As a player, I want `rewind` to be excluded from goal rewards (or very rare), so that the flagship feature stays special.
73. As a player, in later slices, I want business rewards (bigger offers, new buyer types, better terms, landmark contracts), market rewards (a press bump in the Ticker, buyer loyalty, first refusal on scarce ore), staff rewards (traits, techniques, XP), office rewards (objects), faction rewards (perks, intel, aggression cooldown) and knowledge rewards (recipe knowledge, reveals), so that rewards grow with the ladders.
74. As a player, I want some rungs and ladder completions to give permanent upgrades or badges, so that my achievements stay visible.

### Twists

75. As a player, I want at most one mid-week twist per week, drawn from the simulation, so that a week can surprise me.
76. As a player, I want twists to be only opportunities or neutral ("the buyer will take double if you can manage it"), never setbacks, so that a twist is a gift, not a trap.
77. As a player, I want to be able to ignore a twist at no cost, so that it's opt-in.

### Writing and art

78. As a player, I want the meeting's humour to be warm, bickering and affectionate, with running gags (James correcting the minutes, Archie's "catering", Owen's unasked questions, Archie's threats to poach Owen), so that the meeting has a personality.
79. As a player, I want the meeting scene to reuse a fixed pose set over venue plates, so that art cost stays flat as venues upgrade.

### Content author / developer

80. As a content author, I want goal templates authored as JSON data (pitcher, ladder, rung, premise condition, metric, tier multipliers, reward per tier, pitch/why/label/minutes prose variants), so that adding a goal never needs code.
81. As a content author, I want card text to fill tokens from live state (ore name, district, faction, numbers), so that one template reads naturally in many situations.
82. As a content author, I want about 5 templates per voice at launch, written across the slices, so that the meetings have variety from day one.
83. As a content author, I want every new prose file flagged for review and written against the writing guide, so that the tone stays consistent.
84. As a developer, I want all tier numbers, weights and frequencies in data as tunable placeholders, so that playtesting can adjust them without code changes.
85. As a developer, I want the board state to be a pure data tree, so that save, snapshot and Rewind keep working.
86. As a developer, I want each ladder to be its own slice with its own tests, so that the framework can be playtested and adjusted before every ladder is written.
87. As a developer, I want a debug way to jump to a Monday meeting with a chosen state, so that meetings can be tested on-device quickly.

## Implementation Decisions

### Slicing (ticket order)

- **Slice 1 — framework + three ladders.** Board state, the BoardMeetings system, the meeting event, objective condition types, ToDo Board section + Story row, the scripted Week 1 handoff, and three ladders: **Market share** (Archie), **Financial** (James), **Cultivation** (Owen). Archie fills Owen's slot when Owen has no eligible rung. The Act 2 spine's first pinned beat (share target) lands with Market share.
- **Later slices, one ladder each, in order:** Crafting → Landmark deals → Office → Partner → Defuse → Security. Each adds its ladder data, any condition types/premise detectors it needs, its templates/prose, and the reward kinds it introduces. The supplier-contract spine beat lands with Landmark deals; the rival move / weather-or-soften / Partner / debrief beats land with Partner and Defuse.
- **Mid-week twists** are their own slice after the framework is playtested (pool content and frequency to be settled then).
- **Whiteboard UI** is one of the last tickets: a brainstorm-and-align ticket on the new UI and its implementation plan, *before* any whiteboard implementation tickets (see Further Notes).
- Each slice ends at a playtestable state; tune before starting the next.

### Modules

- **BoardMeetings (new system, static funcs, the main seam).** Owns `state.boardMeetings`. Responsibilities:
  - `eligible_cards()` — for every ladder, the next rung the player qualifies for whose premise is true and whose target is not already met; rungs already met in state are recorded as skipped.
  - `agenda(week)` — the three offered cards: pinned spine card first (if any), then a seeded weighted pick from eligible cards, one per distinct voice, with Archie filling Owen's slot when Owen has none. Seed = save seed + week number, so Rewind to Monday reproduces it.
  - `choose(card_id)` — writes the active goal (an objective instance, below), records the pick, awards the pitcher's warmth, bumps unpicked voices' weights.
  - `skip()` — chooses Archie's offered card (his pinned card wins if he holds one; otherwise his highest-weighted card) and flags the minutes line as a skip.
  - `note_progress()` — called at the same action boundaries the objectives evaluator runs on; locks the stretch tier the moment it's hit.
  - `judge_week()` — at Monday rollover, before the meeting: resolves the active goal to `missed | base | target | stretch` (best of the locked tier and the tier met now), pays that tier's reward, appends a history entry, clears the active goal.
  - Emits `state_changed`; never touches nodes.
- **Objectives (existing, extended).** New condition types evaluated by the existing engine, so board goals are tracked like every other objective:
  - `ore_share_at_least` (producer player, ore type, fraction; reads the Shares 7-day window),
  - `reserve_weeks_at_least` (cash ÷ the business's real weekly expenses ≥ n),
  - `yield_multiple_at_least` (player harvest over the goal week ≥ multiple × the prior 10-day average daily yield × 7, baseline captured at choose time),
  - later slices add their own types (crafting share, recipe tier, contract signed, relation/stance reached, security level, etc.).
  - A board goal is a **generated objective instance** stored in board state (not in the static objectives data); the evaluator must be able to evaluate a definition passed in, not only ones from data. Tiers are evaluated as three thresholds of the same condition.
- **Todo (existing, extended).** New "Board" section: the active goal's label, current tier reached, progress toward the next tier, and the Act 2 spine beats as items (active/done/placeholder like other questlines). `current_objective()` must be able to return the board goal so the Story row reads it.
- **DailyBrief (existing, extended).** The Story row shows the active board goal and progress when no questline step outranks it. Precedence rule: an active questline objective from another questline (Tutorial, Collective) still shows first; board goal otherwise.
- **Meeting event (new event data + light Events support).** A normal event: Minutes cards → Agenda hub → AOB cards → exit. The Agenda hub's three options are generated from `agenda(week)`; the hub also offers an exit that calls `skip()`. Card text uses token substitution from a context dictionary built by BoardMeetings (pitcher, pitch line, why-this-week, tier numbers, reward preview, last week's result). Events needs a way to take hub options from a context-supplied list rather than only authored options; keep this generic (not board-specific) and minimal.
- **Rollover.** On the rollover into a Monday: `judge_week()` runs after payday/contract renewal (so financial goals see the week's real books), then the meeting is queued to start the next time the player is free (start-or-defer, like other quest events). The meeting itself spends no time block.
- **Business quest hand-off.** The Act 1 closing sets the flag that enables board meetings; the first Monday on or after that flag is Week 1 (the scripted meeting). The unbuilt Act 2 questline beats are not built as a separate questline; they become board rungs.

### Data

- **New board data file** (loaded once at boot into GameData):
  - `voices`: archie / james / owen — display name, contact id, base weight, unpicked-weight bump, warmth on pick, pitch-rarity (Owen low).
  - `ladders`: id, voice(s), ordered rungs. Each rung: id, premise condition (must be true to appear), goal condition type + params, tier scaling (`base`/`target`/`stretch` multipliers or absolutes), length (weeks, default 1), rewards per tier, `pinned` flag + `spine` beat id for Act 2 rungs, `permanent` reward flag.
  - `templates`: per rung, prose variants for pitch, why-this-week, label (≤ ~25 chars), and minutes reactions (success / base-only / miss), plus AOB one-liner pool and skip line. All PROSE-REVIEW.
  - `tuning`: unpicked-voice bump, warmth amount, competing-pitch cap (≤ 1 week in 5), history length kept, Archie-skip rule.
- **Slice 1 placeholder tiers** (tunable; to be confirmed in playtest):
  - Market share: absolute player share of one ore type over the 7-day Shares window — base 20%, target 25%, stretch 30%. The first rung is the Act 2 share beat.
  - Financial: cash reserve covering n weeks of the business's real weekly expenses — base 2, target 3, stretch 4.
  - Cultivation: harvest over the goal week vs. the prior 10-day average — base ×1.1, target ×1.25, stretch ×1.4.
- **Slice 1 rewards:** cash, `timePearl`, `enhancementPowder`, faction relation, story vignette (a short event or text). `rewind` is excluded. Each tier lists its rewards explicitly; preview text is generated from the same data.
- **Warmth** uses each founder's existing contact relation (Archie, James and Owen all already have one); picking a voice's card awards a small relation amount; not picking awards nothing.

### State (pure data — no references)

`state.boardMeetings`:

- `enabled` (bool), `week` (int, meeting count), `firstMeetingDay` (int)
- `agenda` — the current week's offered cards as plain dictionaries (template id, rung id, voice, resolved tier numbers, reward preview, rendered text keys), so Rewind restores exactly what was shown
- `active` — the chosen goal: objective instance definition, voice, rung id, tier thresholds, baseline snapshot (e.g. 10-day yield average), `lockedTier`, chosen day, skip flag
- `voiceWeights` — per-voice current weight
- `rungs` — per ladder: per rung `done | skipped` with day
- `spine` — Act 2 beat ids → `pending | done`
- `history` — capped list of `{week, voice, rung, result, reward}` for minutes and memory lines
- `lastCompeting` — week of the last competing-pitch beat (for the 1-in-5 cap)

### Act 2 spine rules

- Beats 1 (share target) and 2 (4-week supplier contract) are **pinned**: whichever is next occupies one agenda slot every week until chosen; the player may pass on it. Beat 2 unlocks when beat 1 is done.
- Remaining beats (rival's first move, weather-or-soften, Partner stance, debrief) are **unordered**: each completes whenever its condition is met, chosen or not; when all are done the debrief event fires and Act 2 is marked complete. The rival's first move itself stays live (a text), not a Monday item.
- James's "which ores are contested" tip lives in the share card's why-this-week line.

### Rules settled in conversation

- Goals are judged at the next Monday meeting; the stretch tier locks mid-week when hit; the reward is the best of locked tier and tier met at judgement.
- Skipping = the meeting's exit option; Archie picks his own card.
- One active board goal at a time; 2-week projects are a later-slice option (length field exists from slice 1, default 1).
- Picking never punishes; unpicked voices get a weight bump; warmth only goes up.
- Opportunities go to the meeting; threats stay live. Archie side deals, favours and partner asks are unchanged in this spec.

## Testing Decisions

- **Good tests check external behaviour only:** given a game state (shares, cash, expenses, vein yields, contact relations, flags, day), call a system's public function and assert on the resulting state or returned data — never on private helpers or internal ordering. Set state directly; never loop on a game-state condition (see CLAUDE.md test hygiene); run each new test file alone under a timeout first.
- **Seam 1 — BoardMeetings (main).** Tests cover:
  - eligibility: a rung appears only when its premise is true; a rung already met is skipped; Owen absent → Archie fills the slot; three distinct voices
  - determinism: same save seed + week → same agenda; choosing a different card after restoring a snapshot works
  - pinned spine card always present until taken; passing on it keeps it next week
  - `choose`: active goal written, pitcher warmth up, others unchanged, unpicked weights bumped
  - `skip`: Archie's card chosen
  - stretch lock: hit stretch mid-week, drop below, still judged stretch
  - `judge_week`: correct tier for missed/base/target/stretch; correct rewards paid; history appended; active cleared
  - Act 2: unordered beats complete in any order; debrief fires when all done
  - state purity: board state survives a save/load round trip unchanged
- **Seam 2 — Objectives.** New condition types each get threshold tests (just below / at / above) in the style of the existing objectives tests, including evaluating a passed-in (generated) definition.
- **Seam 3 — Todo / DailyBrief.** The Board section lists the active goal with tier progress and the spine beats; the Story row shows the board goal when no higher questline step is active, in the style of the existing todo and daily brief tests.
- **Meeting event (thin).** The Agenda hub renders the three agenda cards as options with tokens filled, plus the skip exit, in the style of the existing events tests.
- **Rollover integration (one test).** Rolling into a Monday with an active goal judges it after payday and queues the meeting.
- Prior art: the existing objectives, business quest, todo, daily brief and events test files.

## Out of Scope

- **Whiteboard UI** — the post-it board as pick UI and mid-week goal view, doodles, post-it overlay layer. Only a placeholder ticket for brainstorm-and-align is in scope (one of the last tickets).
- **HQ office venue** and office tiers beyond what the Office ladder slice defines; the meeting stays in James's workshop until then.
- **Mid-week twist pool content** — the twist slice settles pool and frequency after framework playtest.
- **Landmark contract balance** (count, pay, term) — authored per rung in the Landmark slice and tuned in playtest.
- **Partner/Defuse detector thresholds**, **security voice** final choice, **permanent badges display location** — settled in their slices.
- New board attendees beyond Archie, James, Owen.
- Changes to Archie side deals, faction favours, partner asks, raid/alarm/wage flows.
- Final art (pose set, venue plates) — produced through the storyboard/compositor pipeline per meeting scene; tickets may reference it but don't block on it.

## Further Notes

- **Whiteboard brainstorm ticket (required).** When ticketing, include, as one of the last tickets, a `ready-for-human` ticket to brainstorm and align on the whiteboard UI (the player picks the week's focus on the whiteboard; the pick becomes the goal shown in the ToDo app) and to plan its implementation. The direction under consideration is that the whiteboard replaces the Agenda hub's pick step and serves as the mid-week view, reading the same board state and objective instance — so no second tracker. Do not ticket whiteboard implementation until that ticket is resolved.
- **The tracker** (objectives → ToDo → Story row) is the single source of "what am I doing"; any board feature that needs its own progress UI should read from it, not duplicate it.
- **Prose:** all meeting, card, minutes, AOB and vignette text is new prose — follow `docs/CONTENT-GUIDE.md` and `docs/writing-guide.md`, one prose ticket per beat, flag PROSE-REVIEW. The register is warmer and sillier than usual but the same voice.
- **Placeholders:** every number in this spec is a playtest placeholder; REFERENCE.md gets a Board Meetings section when slice 1 lands, marked TBD where unconfirmed.
- **Vocabulary:** Week 1 = the first meeting; "rung" = one step of a ladder; "pinned card" = a spine card that holds an agenda slot until taken; "voice" = a pitching founder.
- **Act 2 spec:** `.scratch/biz-empire-act2/spec.md` stories 93–104 (the questline) are superseded by this spec; its systems stories are unaffected.
- **Relevant code for ticketing:** objectives evaluator, todo, daily brief, business quest (Act 1 closing / flags), events (hub, context tokens, start-or-defer), shares (ore share windows), business/payroll and morning accounts (weekly expenses), cultivating/shares ore tally (yield), contacts (relation), calendar (Monday helpers), time system rollover (Monday steps ⑥.4).
