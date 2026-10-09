# Opening hour: choices, rolls and continuity

Status: ready-for-agent

Source: `docs/reviews/review-2026-10-09.md` §18 (P1, agreed by the owner 2026-10-09), §3, §7. Builds on `.scratch/writing-revamp/` (intro proposal 2 is applied; James proposal 2 is pending).

## Problem Statement

A new player spends roughly the first 45 minutes tapping → through about 80 event cards (intro, buyer, James meeting, Archie catch-up, home raid) without making a single decision. The game keeps telling them they're a participant while giving them nothing to do.

When choices do exist elsewhere in the game, their outcomes are fixed. A `chance` effect exists, but the player can't see the odds, the text can't change with the result, and nothing the player has done, owns or is good at affects it.

The opening is also incoherent about time and facts:
- The top board says Monday morning while cards say "Earlier tonight", "half ten on a Tuesday", "The next morning… tonight", "Two days later" (after a text that said "Tomorrow"), and "3:14 AM".
- The phone's date widget shows a fixed "Tue, 14 May 08:14".
- "Rent is due Friday" when bills land on Monday.
- The player texts that they have calc to sell when Archie holds it.
- The raid debriefs mention "your ore" when the player owns none.
- The raid intro mentions "flatmates" in a single-room bedsit.
- Archie hands over "the vein I said I'd give you", but the word "vein" has never appeared on screen.

## Solution

Each opening event gets 1–2 meaningful choices, about 9 in total, and roughly a third of the card count is trimmed. Some choices resolve by a **check**: a visible success chance built from a base plus modifiers drawn from the player's earlier choices, skills, relations and items.

- The player sees the odds on the button and can open a short list of what's helping or hurting.
- They can optionally spend an item to improve the odds.
- The result text and effects differ on success and failure. A short branch can follow before the story rejoins.
- Earlier choices pay off later. Asking the right question in the intro makes haggling with Marcus easier; telling James about the jar shapes what he says next.

The event engine gains the check, option gating, choice memory and short branches. Every event can declare when it happens, so the board, the card labels, the art and the phone clock agree. The opening's factual errors are fixed, and "vein" is introduced before the player is given one.

## User Stories

1. As a new player, I want to make a decision within the first few cards of the intro, so that I feel like a participant rather than a reader.
2. As a new player, I want each opening event to offer at least one meaningful choice, so that the first hour feels like a game.
3. As a player, I want to see the success chance on a risky option before I pick it, so that I can make an informed decision.
4. As a player, I want to tap an info control on a risky option and see which factors raise or lower my chance, so that I understand why the odds are what they are.
5. As a player, I want my earlier choices to show up as named modifiers ("You asked the right questions +15%"), so that I can see the consequences of what I did.
6. As a player, I want my skills to improve relevant checks, so that getting better at things matters outside their own screen.
7. As a player, I want my relationship with a character to affect checks involving them, so that investing in relationships pays off.
8. As a player, I want to optionally spend a consumable to improve a check, so that my inventory gives me options in story moments.
9. As a player, I want an item to be used up only if I actually toggled it on and committed the choice, so that I never lose items by accident.
10. As a player, I want to see why an option is unavailable ("Needs £50", "Needs a Time Pearl"), so that I know what preparation would open it.
11. As a player, I want options I don't qualify for to be either hidden or shown disabled as each one's data specifies, so that hidden surprises and visible goals both exist.
12. As a player, I want success and failure to read differently and change different things, so that the roll feels like it mattered.
13. As a player, I want a failed roll to cost me something proportionate (cash, HP, a relation point, a worse start to a fight) rather than ending the story, so that risk-taking stays fun.
14. As a player, I want a few choices to lead to short alternative scenes that rejoin the main story, so that my path feels personal without the story fragmenting.
15. As a player, I want Rewind to undo a choice I regret, so that the flagship Rewind feature still works in events.
16. As a player, I want rewinding and picking the same option with the same preparation to give the same result, so that rolls carry real stakes and can't be fished.
17. As a player, I want changing my preparation (using an item, picking another option) after a rewind to be able to change the outcome, so that Rewind rewards rethinking.
18. As a player, in the intro, I want to choose how I answer Archie's pitch (go along, ask who the buyers are, or demand half), so that my character's attitude is mine.
19. As a player, when the knife comes at me in the intro, I want to choose to freeze, step in front of Archie, or grab for the bag, with visible risk on the bold options, so that the danger demands a reaction.
20. As a player, if I fail the bold option in the knife scene, I want a real but survivable cost (an injury that lowers my HP for the next few days, remembered later), so that danger is sincere.
21. As a player, if I succeed at grabbing for the bag, I want to come away with a little calc of my own, so that later lines about "your ore" are true for me.
22. As a player, in the pub, I want to choose what to ask Archie (what calc is, what it's worth, where it comes from), so that exposition comes at my pace.
23. As a player, I want the word "vein" and the idea of a vein in Whitechapel to be introduced before I'm handed one, so that the core asset makes sense when I receive it.
24. As a player, at the Marcus sale, I want to choose to take the offer, push for more (a check), or let Archie handle it, so that I make my first trading decision.
25. As a player, I want the cash I receive from the buyer sale to match what the story says (including any split I negotiated in the intro), so that the numbers are trustworthy.
26. As a player, at James's unit, I want to choose whether to tell James that the jar moved when I leaned in, so that my relationship with James and the mystery have a starting point I chose.
27. As a player, I want the time-pearl lesson to be a decision about how I work (take my time, rush it, ask James to watch), with the number of pearls I make depending on rolls, so that my first craft is something I did.
28. As a player, I want the pearls I made at James's to be the pearls I own afterwards, so that the lesson has a tangible result.
29. As a player, when Archie asks how it went with James, I want to choose whether to show him a pearl, so that small social choices have small effects.
30. As a player, when someone breaks in at night, I want to choose to ambush, bluff that I've called the police, or stay still, each with clear stakes, so that the raid starts with my decision.
31. As a player, if my ambush succeeds, I want the fight to start with the intruder already hurt, so that preparation and nerve pay off in combat.
32. As a player, if my police bluff succeeds, I want the intruder to flee without a fight and the story to continue on the "you handled it" path, so that non-violent solutions are real.
33. As a player, if my bluff fails, I want the intruder to act first in the fight, so that the failure has a combat consequence.
34. As a player, if I stay still, I want to lose what the intruder takes and continue on the "loss" path without a fight, so that passivity is a legitimate but costly choice.
35. As a player, I want having a Time Pearl equipped to improve my ambush chance, so that the lesson at James's feeds the raid.
36. As a player, I want the raid debrief to talk about what I actually own (pearls, stuff, or ore if I have it), so that the story doesn't contradict my inventory.
37. As a player, I want the raid intro to describe my actual home (a single room), so that the setting is consistent.
38. As a player, I want Archie's vein handover to refer back to our pub conversation if I asked about it, and introduce it plainly if I didn't, so that the handover always makes sense.
39. As a player, I want Archie's cultivation tutorial to explain cultivate, light prune and hard prune with one consistent model and no garden metaphors, so that I understand the vein mechanics.
40. As a player, I want the board's day and block, the card labels and the art to agree about when a scene happens, so that time feels real.
41. As a player, I want "tonight" scenes to happen in the evening block and "tomorrow midday" scenes to happen the next afternoon, so that texts and events line up.
42. As a player, I want the phone's status-bar clock and date widget to show the game's current day and time of day, so that the phone feels like my phone.
43. As a player, I want the rent deadline in the story to match when the bill actually lands, so that the opening threat is honest.
44. As a player, I want my own texts to Archie to reflect who actually holds the calc, so that dialogue doesn't contradict the scene I just watched.
45. As a player, I want the opening to be noticeably shorter (about 50 cards instead of about 80), so that I reach the actual game sooner.
46. As a player, I want odds and modifiers to read cleanly at phone width in the existing event card style, so that checks feel native to the event screen.
47. As a player with reduced motion on, I want the check result to appear without extra animation, so that my preferences are respected.
48. As a content author, I want to add a check to any choice option in event JSON (base, modifiers, clamp, display mode, success and fail outcomes), so that every future event can use rolls without engine work.
49. As a content author, I want modifiers that can read a flag, a recorded earlier choice, any numeric state path (e.g. a skill), a contact relation threshold, held cash, or an optional consumable, so that most story logic needs no code.
50. As a content author, I want each modifier to carry a short player-facing label, so that the odds breakdown is written in the game's voice.
51. As a content author, I want to gate an option with a `requires` condition and choose whether it's hidden or shown disabled with a reason, so that I can design both secret and aspirational options.
52. As a content author, I want every choice the player makes in an event recorded under a stable key, so that later events can reference it without me inventing ad-hoc flags.
53. As a content author, I want an outcome to optionally jump to a later card in the same event, so that I can write short branches.
54. As a content author, I want events to declare their timing (block, and whether they move the clock), so that continuity is data rather than prose discipline.
55. As a content author, I want a test to fail when a card label's time words contradict the event's declared timing, so that continuity errors are caught automatically.
56. As a content author, I want the desktop and mobile quest editors to support the new fields, so that I can author checks without hand-editing JSON.
57. As a content author, I want existing events with plain choices or the old `chance` effect to keep working unchanged, so that nothing regresses.
58. As the owner, I want new prose drafted through the writing-revamp proposal process and flagged `PROSE-REVIEW:`, so that I keep control of the game's voice.
59. As the owner, I want the composited event art for the intro preserved, with any new or branched cards listed for a storyboard pass, so that the art work isn't wasted.
60. As a developer, I want save files from before this change to load (missing choice memory or timing fields backfilled), so that playtest saves survive.

## Implementation Decisions

### Event engine (the Events system: one seam)

- **Choice options gain three optional fields: `check`, `requires`, and outcome objects.** Plain options (fixed `result_text` + `effects`) stay valid and unchanged.
- **Check shape.** The shape below comes from the review's proposal and encodes the decision:

  ```jsonc
  "check": {
    "base": 0.40,
    "mods": [
      { "flag": "<flag>", "add": 0.15, "label": "…" },
      { "choice": { "event": "intro", "card": 6, "option": "brave" }, "add": 0.10, "label": "…" },
      { "path": "player.craftingSkill", "perPoint": 0.05, "above": 1, "label": "…" },
      { "relation": "archie", "atLeast": 15, "add": 0.10, "label": "…" },
      { "cash": { "atLeast": 50 }, "add": 0.05, "label": "…" },
      { "item": "timePearl", "equipped": true, "add": 0.15, "label": "…" },
      { "item": "prophetsBreath", "optional": true, "consume": true, "add": 0.25, "label": "…" }
    ],
    "min": 0.05, "max": 0.95,
    "show": "odds"            // "odds" | "hint" | "hidden"
  },
  "success": { "result_text": "…", "effects": [ … ], "goto": null },
  "fail":    { "result_text": "…", "effects": [ … ], "goto": null }
  ```

- **Odds.** `base` plus every matching modifier, clamped to `[min, max]`. Optional item modifiers count only when the player has toggled them on. The `hint` display maps odds to words (e.g. Likely ≥ 65%, Even 35–64%, Risky < 35%); the thresholds live in data.
- **Odds query.** Add a pure query on the Events system that returns, for an option, the final probability and the list of applied modifiers (label + signed delta), given the current toggles. The screen reads only this; it never computes odds.
- **Item toggle in state.** The optional-item toggle is kept in the event's state (pure data) so Rewind and save capture it. Consumed items are removed only when the option is committed.
- **Deterministic rolls.** A check's roll is derived from the game seed, event id, card index, option index and the set of toggled optional items (a stable hash to [0,1)). It doesn't consume the global RNG stream. Same inputs give the same result after a Rewind; different inputs may differ.
- **Choose returns the outcome.** Choosing an option with a check records which outcome happened, shows that outcome's `result_text` as the resolution card, and applies its effects. An outcome `goto` sets the next card index (forward only, same event). Without `goto`, play continues to the next card as today.
- **Gating.** `requires` uses the same condition vocabulary as modifiers (flag, choice, path ≥, relation ≥, cash ≥, item held/equipped), plus `"display": "hide" | "disable"` and a `reason` string for disabled options.
- **Choice memory.** Every committed choice (with or without a check) is recorded in state under the event id and card index: the option's stable `id` (a new optional option field, falling back to its index) and, for checks, success/fail. It's readable by modifiers, `requires` and objectives. The store lives in the flags area of the state tree and is backfilled empty on load.
- **Existing `chance` effect.** Unchanged and kept for invisible background rolls.

### Event timing and continuity

- **Optional `at` on events.** `{ "block": "morning" | "afternoon" | "evening", "advance": true|false }`. With `advance`, starting the event moves the world clock forward to that block on the current day (never backwards). If the block has already passed, the event starts in the current block and a content lint flags the mismatch. Rollover-time events (the home raid) declare `"block": "night"`, which never moves the clock.
- **Board refresh.** The top board updates as soon as the block changes.
- **Calendar start.** The opening runs on a Tuesday evening to match the intro's established prose. The calendar's start weekday becomes data-configurable so day 1 is a Tuesday, with the intro running in the Evening block. Weekly Monday billing is unaffected: the first bill lands on day 7. The tutorial's existing "rest to next morning" flow is unchanged.
- **Rent day.** The story's rent deadline is changed to Monday (bills land on Monday per ADR 0006). The owner can instead keep "Friday" in prose and move the bill day, which is a data change. Recorded as a Further Note, not a blocker.
- **Phone clock.** The phone shell's status-bar time and date widget derive from the world day (via the calendar) and current block, with a fixed representative clock time per block (e.g. Morning 08:xx, Afternoon 14:xx, Evening 20:xx; values in data). Weather and tagline stay presentation-only.
- **Generated labels.** Card labels may use tokens for the current weekday/date and relative day so they can't drift. A content lint test checks label time words against `at`.

### Combat entry from events

- **Home raid entry options.** The home-raid combat request accepts opening modifiers from the event: an enemy starting-HP multiplier, and "enemy acts first".
- **Resolving without a fight.** A new effect resolves the home raid as a win or loss without combat, routing to the same debrief events the combat outcome uses today. The debrief choice stays centralised in one place.
- **Intro injury.** The injury is a current-HP reduction applied by the event, plus a flag referenced by later prose. It doesn't add a new max-HP modifier system.

### Content (beats; prose via the writing-revamp process)

The beat table in review §18.4 is the content brief: intro ×3 choices, buyer ×1 (+ split), James ×2, Archie catch-up ×1, home raid ×1 three-way, for about 9 choices and 4–6 rolls.

- **Baselines.** The intro uses proposal 2 (applied). James uses proposal 2 (pending) as its starting text.
- **Factual fixes:**
  - The tutorial message the player sends Archie no longer claims the player holds calc.
  - The raid intro refers to the player's single room.
  - The debriefs refer to what the player owns, with an ore line only if they hold ore.
  - The vein handover branches on whether the pub "where does it come from?" question was asked.
  - Archie's cultivation speech uses one model (cultivate up; light prune takes some and leaves it growing; hard prune takes more and sets it back; leave it dead and it's gone), with no garden metaphor.
- **Card budget.** About 50 cards across the opening events.
- **The writing guide** currently says "keep existing `choices[].effects`". For these events, the spec's beat table supersedes that, and the guide gets a note.

### Presentation (Event screen)

- **Option buttons** show the label plus odds ("Push for more · 60%") or the hint word, and an info control that opens a small sheet listing applied modifiers. Disabled options show their reason.
- **Optional item toggles** appear under the option they apply to.
- **The resolution card** shows the outcome text, with a subtle success/fail marker in the existing card style.
- **Art.** New or branched cards without art fall back to the previous card's image under the existing auto-discovery rule. The list of cards needing new plates goes to the event-storyboard process.

### Tools

- The desktop and mobile quest editors support `check`, `requires`, outcome objects, option `id`, and event `at`.

## Testing Decisions

- **What a good test looks like here.** Tests drive whole events through the Events system's public API (start, choose with toggles, advance, revealed cards, odds query, rewind) and assert on GameState: cash, items, flags, choice memory, world block, the started combat request or debrief. They don't assert on internal helpers, intermediate dictionaries or rendering details.
- **Seam (agreed with the owner).** The Events system API, one seam. Scenario-style tests play the opening chain intro → buyer → James → Archie catch-up → home raid along several paths (cautious, bold-success, bold-fail, bluff, passive). They assert the payoffs land (e.g. the asked-questions flag raises the Marcus odds; an equipped pearl raises the ambush odds; the passive path reaches the loss debrief without combat).
- **Engine cases.**
  - Odds clamp, and each modifier type.
  - Optional item counted only when toggled, and consumed only on commit.
  - The same seed and inputs give the same outcome after a rewind, and a changed toggle can change it.
  - `goto` moves forward only.
  - `requires` hide vs disable with reason.
  - Plain choices and the legacy `chance` effect are unchanged.
  - `at` advances the clock forward and never back; a night event never moves it.
  - Save backfill for choice memory.
- **Content lint.** A data test over every event file: label time words agree with `at`; every `goto` targets a later card in the same event; every modifier and `requires` references a known flag, item, contact or state path; no option has both fixed `result_text` and a `check`.
- **Screen.** The existing event-screen tests are extended only to confirm the odds text, info sheet, disabled reason and item toggle render from the odds query.
- **Prior art.** The existing events test file (choices, rewind, image discovery), the Collective Act 1/2 scenario tests (playing events and asserting state), the event-items tests (item use inside events), and the district-events tests (deck data lint style).

## Out of Scope

- Intent-telegraph combat and combat balance (parked; review §19). The raid's opening modifiers are the only combat change.
- Rewriting events beyond the opening chain. The Collective, Business Empire and district deck events adopt checks later; district deck expansion is a separate effort (review §24).
- Poverty consequences for arrears (review §20).
- A general max-HP or injury status system.
- New art production. This spec only lists cards needing plates.
- Travel time costs (deferred).

## Further Notes

- **Rent day.** Owner preference needed: prose says Friday (intro proposal 2) while bills land on Monday. This spec defaults the prose to Monday; flip by moving the bill day in data if Friday is preferred.
- **Calendar start.** Moving the calendar start to a Tuesday changes every dated string in existing saves' first week. Acceptable for playtest saves, but call it out in the ticket.
- **Pacing.** Rolls in a tutorial can frustrate. Keep tutorial failures mild and never blocking: every path reaches the vein handover. Consider a slightly generous `min` (e.g. 0.15) for opening checks.
- **New prose.** All new prose must be flagged `PROSE-REVIEW:` and delivered as writing-revamp proposal files before touching event data.
- **Ticket order.** Suggested breakdown: engine check + odds query + choice memory → requires + goto → timing/`at` + phone clock + label lint → home-raid entry options and no-fight resolution → editors → content per event (intro, buyer, James, catch-up, raid) → continuity fixes.
