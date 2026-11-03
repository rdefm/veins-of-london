# Board prose cards — spec

**Status:** ready-for-agent

Follows the board-meetings feature (`.scratch/board-meetings/spec.md`) and its debate rework (`.scratch/board-meetings/debate-rework.md`). Supersedes the fixed-slot goto layout of the board meeting event (REFERENCE §3.15 "Meeting event").

## Terms

- **Agenda card**: an offered rung on a week's agenda (existing term, REFERENCE §3.15).
- **Event card**: one screen of an event (existing term).
- **Prose card**: new. An authored unit of meeting prose for one ladder goal (template) or for the generic debate. It holds one or more event cards, plus a slot, a voice, an optional `when` condition and a weight.
- **Prose pack**: new. The file of prose cards for one template, or for the generic debate, or for the Week-1 explainer.
- **Meeting facts**: new. The named business facts worked out once per meeting. Prose card conditions and `{tokens}` both read from them.
- **Splice**: new. An event card type that expands, when the event starts, into a list of event cards supplied by the event's context.

## Problem Statement

From week 2 on, board meetings put 1-3 goals to the player, chosen by the state of the business. The prose for each goal has to fit what is really happening in the business and change a lot from week to week. Today:

- Each goal gets one line per slot (`case`). A goal can't have a multi-card argument, its own images, or replies written for that argument. The generic replies, picked at random, often don't answer what was just said, which breaks the debate rework's prose principle 3.
- Which line plays depends only on the seed. Business state reaches the prose through number tokens, never through which prose is chosen. Archie can't argue differently after a missed week, a shrinking float or a rival undercut.
- The meeting event is a fixed 3-slot run, wired with goto flags (`c<i>_last`, `c<i>_norebut`, `noclash`). The wiring grows with every new beat and can't hold slots of varying length.
- All meeting prose sits in one large board data file. The writer can't see a line in the phone frame, can't see which variants can fire in a given state, and can't tell where pools are thin. The storyboard tool can't open it.
- Week 1 is a separate hand-built event that repeats the debate wiring.

## Solution

Meeting prose becomes **prose cards** grouped in **prose packs**, one pack per ladder goal plus a generic debate pack and a Week-1 pack. When a meeting starts, the board system works out the **meeting facts**, picks the prose cards whose `when` holds (a weighted seeded pick that avoids repeating last week), and hands the chosen event-card lists to the meeting event through its context. The meeting event becomes a straight run of **splice** cards: minutes → opener → slot 0 → slot 1 → slot 2 → clash → vote → AOB. An empty splice adds nothing, so no goto flags are needed.

A goal's case card can carry its own authored exchange (case → reply → rebuttal) as one mini-scene. The generic debate pool fills in only when a case card brings no reply of its own.

The writer edits the packs in a new **Prose pack** mode of the storyboard tool. It shows packs, slots and variants with their conditions and weights. A **meeting sandbox** puts together a sample meeting in the phone frame from goals and facts the writer picks, with a seed they can reroll. A **coverage grid** shows how many prose cards can fire per goal × slot × fact range. Edits save straight into the live prose packs. Git is the undo, and the game's load lint guards against bad data.

## User Stories

### Player
1. As a player, I want each week's board meeting to argue about what is actually happening in my business, so that the meeting feels like it is about my firm.
2. As a player, I want a goal's pitch to change when the situation behind it changes (a missed week, a shrinking float, a rival undercutting), so that I don't hear the same speech in different circumstances.
3. As a player, I want replies in the debate to answer what the pitcher just said, so that the meeting reads like people arguing, not lines taking turns.
4. As a player, I want the same goal to come back with fresh wording in later weeks, so that repeat goals don't feel copy-pasted.
5. As a player, I don't want to hear the same prose card two weeks running, so that back-to-back meetings feel different.
6. As a player, I want a goal's argument to run across several event cards when it needs to, so that bigger proposals get room.
7. As a player, I want a meeting with fewer than three goals to flow with no gaps or stray cards, so that short meetings feel finished.
8. As a player, I want Rewinding to a point before a meeting to replay the same meeting, so that Rewind stays trustworthy.
9. As a player, I want the vote, skip, result and AOB to work exactly as they do now, so that the prose change doesn't change the rules.
10. As a player, I want Week 1 to keep its explainer and the Owen-poach gag before running the same debate, so that my first meeting still teaches me the format.
11. As a player, I want prose cards to be able to show their own image keys, so that a big pitch can cut to its own shot.
12. As a player, I want the alternate voice (James pitching `share_leader`) to get prose in his own voice, so that alt-voice pitches sound right.

### Writer
13. As the writer, I want one prose pack per ladder goal, so that I can find and edit everything for a goal in one place.
14. As the writer, I want each prose card to name its slot (case, reply, rebuttal, chosen, concede, aftermath), so that I know where it plays.
15. As the writer, I want each prose card to name its voice, so that pitcher and responder lines are written for the right person.
16. As the writer, I want to give a prose card a `when` condition on meeting facts, so that I can write variants for particular business states.
17. As the writer, I want to give a prose card a weight, so that I can make some variants rarer.
18. As the writer, I want a case card to carry its own authored reply and rebuttal, so that the exchange stays coherent.
19. As the writer, I want the generic debate pool to fill in only when a case card has no reply of its own, so that I can write mini-scenes step by step without leaving holes.
20. As the writer, I want conditions to use plain named facts (share, share_gap, float_weeks, last result, streak, rival present, who pitched last week), not raw state paths, so that I can write conditions without knowing the save format.
21. As the writer, I want `{tokens}` and conditions to read the same facts, so that the numbers in a line always match the situation that picked it.
22. As the writer, I want to open prose packs in the storyboard tool, so that I edit prose where I already work on events.
23. As the writer, I want to see a pack's variants grouped by slot, each with its condition and weight, so that I can see at a glance what a goal can say.
24. As the writer, I want to edit a prose card's event cards with the same card editor I use for events, so that there is nothing new to learn.
25. As the writer, I want to put together a sample meeting from 1-3 goals I pick, with facts I set by hand, so that I can read a meeting as the player would.
26. As the writer, I want to reroll the sandbox seed, so that I can see different variants for the same situation.
27. As the writer, I want the sandbox to show which prose card fired in each slot and why (its condition and weight), so that I can fix a wrong pick.
28. As the writer, I want the sandbox to flag any `{token}` left unfilled, so that broken lines show up before the game.
29. As the writer, I want a coverage grid of goal × slot × fact range showing how many prose cards can fire, so that I can see where the same prose will keep repeating.
30. As the writer, I want gaps (zero cards) and thin spots (one card) highlighted, so that I know where to write next.
31. As the writer, I want edits to save straight into the live prose packs, so that I don't need a separate Promote step.
32. As the writer, I want to leave "for Claude" comments on prose cards, as on events, so that I can hand rewrite work to an agent.
33. As the writer, I want to add, duplicate and delete prose cards in the tool, so that writing variants is quick.
34. As the writer, I want the Week-1 explainer kept as its own prose pack, so that I can edit it beside the debate.
35. As the writer, I want the generic debate lines (opener, reply, rebuttal, clash, chosen, concede) in their own pack, so that fallback prose has one home.

### Developer / agent
36. As a developer, I want the meeting event to be a straight run of splice cards, so that adding a beat never means rewiring gotos.
37. As a developer, I want splice to be a generic event-engine feature, so that other events (daily brief, calls) can use it later.
38. As a developer, I want the chosen prose to go into the event context as plain data (card lists), so that state stays pure and Rewind keeps working.
39. As a developer, I want prose selection to be deterministic from week + rollSeed + meeting facts, so that tests and Rewind can reproduce it.
40. As a developer, I want the game to reject bad prose packs on load (unknown fact names, tokens with no matching fact, invalid event cards, unknown slot or voice, duplicate ids), so that data mistakes fail early.
41. As a developer, I want a lint rule that every template has at least one case card with no condition for each voice that can pitch it, so that a meeting can never come up empty.
42. As a developer, I want the move to prose packs to be behaviour-identical first (existing pools wrapped as single-card prose cards), so that later steps can be checked against today's behaviour.
43. As a developer, I want the storyboard sandbox's eligibility logic checked against golden results exported by Godot, so that the preview can't quietly drift from the game.
44. As an agent working through implement tickets, I want each prose-writing ticket to touch only its goal's pack, so that tickets 16-26 don't conflict.

## Implementation Decisions

- **Splice event card (events system).** New card type `splice`, naming a context key. When an event starts, each splice is replaced in order by the event-card list under that key. Missing or empty key = zero cards. Spliced cards are ordinary event cards: `fillFromContext`, `speaker` fill, images, and `goto` between spliced and authored cards all behave as normal. Spliced card keys are made unique by namespacing with the splice id. Expansion happens once, at start, and the expanded list is what the live event plays, so a snapshot or Rewind mid-meeting sees a stable card list.
- **Meeting event skeleton.** One meeting event for every week: minutes → opener → splice `explainer` (filled only in Week 1) → splice slots 0-2 → splice `clash` → vote hub (unchanged: `choicesFromContext: "agenda"`, skip exit, results) → AOB. The separate Week-1 event is retired. The `meeting.week1EventId` setting goes away and REFERENCE §3.15 "Meeting start" / "Meeting event" are updated to match.
- **Prose pack schema** (shape agreed in conversation):
  ```json
  { "template": "share_first",          // or "_debate" / "_week1"
    "cards": [{
      "id": "share_first.case.undercut", // unique across all packs
      "slot": "case",                    // case|reply|rebuttal|chosen|concede|aftermath (+ opener|clash|explainer in special packs)
      "voice": "archie",
      "when": { "fact": "share_gap", "gt": 5 },  // optional; Events condition grammar over meeting facts
      "weight": 1,                       // optional, default 1
      "cards": [ { "speaker": "Archie", "text": "…" } ],
      "replies": [ /* optional authored reply/rebuttal prose cards, same shape, for a mini-scene */ ]
    }]}
  ```
  Prose packs are a new data set, one file per template plus `_debate` and `_week1`, loaded by GameData at boot. Template mechanics (label, tiers, rewards, premise) stay in the board data. Only prose moves.
- **Meeting facts (board system).** A new public function works out a flat dictionary of named facts for a week: the existing token values (expenses, float, weeks, share, rival...) plus state facts (share_gap, float_weeks, last result hit/miss/skip, streak of hits, rival present, who pitched last week, week number, ore of the agenda card). It is the only source for both `when` conditions and `{token}` filling. The full fact list is written into REFERENCE §3.15.
- **Conditions.** `when` uses the existing Events condition grammar (`all`/`any`/`not`, comparisons). A new leaf `{fact, op, value}` reads meeting facts. No raw state-path conditions in prose packs.
- **Selection (board system).** For each slot: filter the prose cards by template/slot/voice and `when` → weighted seeded pick (`Rng.stable_unit` on rollSeed|board|week|slot salt, same family as today's picks) → skip a card whose id was picked last week if another qualifies. The ids picked last week are recorded in board state (`boardMeetings.lastProse`, plain strings) so the no-repeat rule is state-pure.
- **Mini-scene resolution.** For agenda card i: pick a case card. If it carries `replies`, pick its reply (and a rebuttal if the reply's stance is `challenge`) from those. Otherwise fall back to the generic `_debate` pack (responder × pitcher × stance, as today). Chosen/concede: goal-specific first, then generic. The resolved event-card lists go into the context as `slot0`..`slot2`, `clash`, `explainer`. The vote hub's option result text uses the same resolution.
- **Context contract.** The meeting context carries card lists, not prose strings. The old `c<i>_case`, `c<i>_resp`, `c<i>_reb`, `clash_a/b` and the `none`/`c<i>_last`/`c<i>_norebut`/`noclash` flags are removed. `agenda`, `voteText`, `minutes` and `aob` stay.
- **Load lint (GameData).** Rejects: unknown slot or voice, a `when` naming an unknown fact, a `{token}` with no matching fact, invalid event card, duplicate prose card ids, a pack naming an unknown template. Also requires, for each template and each voice that can pitch it (including alt voices), at least one case card with no condition.
- **Storyboard tool: Prose pack mode.** A new board kind listing prose packs from the repo folder the tool already opens. Views: pack → slot tabs → variant list (condition, weight, first line); the existing card editor for a prose card's event cards; the meeting sandbox (pick 1-3 templates, edit facts, reroll seed, phone-frame playback, why-it-fired panel, unfilled-token warnings); the coverage grid (template × slot × fact bucket → count of eligible cards, red at 0, amber at 1). Saves straight to the prose pack files. "For Claude" comments are stored in the pack under a `_comments` key, as proposals do today.
- **Sandbox parity.** The JS side matches only the condition evaluation and the eligibility filter. It does not need to match the game's exact seeded pick. A Godot export script writes golden eligibility results (fixture facts → eligible prose card ids per slot) that the JS tests read.
- **Migration order.** (1) Splice + straight skeleton, with today's pools wrapped as single-card prose cards in-engine: the same meetings for the same seed. (2) Move prose into packs. (3) Meeting facts + `when` + no-repeat. (4) Mini-scene replies. (5) Storyboard pack mode, view + sandbox. (6) Editing + coverage + comments. (7) Retire the Week-1 event. Each step keeps the full suite green.
- **Docs.** CODEMAP gains rows for the prose packs and the splice card. REFERENCE §3.15 and §3.9a (event card types) are updated. Board-meeting prose tickets 18/20/22/24/26 are updated to "write the goal's prose pack".

## Testing Decisions

- **What makes a good test:** drive the game through its public entry points and check what the player would see (the played card run, speakers, text, options), not internal helpers or context key names. Fixtures set state directly. Never loop on game state (see the test-hang rules in CLAUDE.md).
- **Seam 1, gameplay (main):** set fixture business state + board agenda → start the Monday meeting through Events → read the live event's expanded card list. Covers facts, `when` filtering, weighted seeded pick, no-repeat, mini-scene vs generic fallback, empty-slot collapse, the Week-1 explainer, and Rewind (snapshot → restore → same run). Prior art: the board meeting tests (`run_case` style, agenda/seed/snapshot cases) and the event tests that start events from fixtures.
- **Splice in isolation (same seam, generic event):** a small fixture event with splices: empty, multi-card, goto into and out of spliced cards, `fillFromContext` inside spliced cards. Prior art: the existing event condition/`choicesFromContext` tests.
- **Seam 2, data lint:** load bad prose pack fixtures and check that each lint rule rejects them with a clear message, and that the shipped packs pass. Prior art: the existing GameData load-validation tests.
- **Seam 3, tool:** `test_storyboard.js` gains prose-pack cases: load/save round trip, sandbox assembly, coverage counts, unfilled-token detection, and eligibility against the Godot-exported golden file. Prior art: the existing proposal/promote tests in that file.
- **Behaviour-identical migration check:** step 1 lands with a test that the same seed + week gives the same played lines as before (captured before the change).

## Out of Scope

- Changing board mechanics: eligibility, agenda building, tiers, rewards, judging, warmth/weights, skip. All unchanged.
- Writing the new prose itself. Per-goal pack prose stays in its own prose tickets (one per beat, against the writing guide, flagged `PROSE-REVIEW:`).
- The midweek-twists and whiteboard-UI brainstorms.
- Using splice in events other than the board meeting (possible later).
- A separate standalone prose tool.
- Storyboard shot/plate features for prose cards beyond showing image keys in the preview.
- Save migration beyond backfilling `boardMeetings.lastProse` as empty (no `saveVersion` bump).

## Further Notes

- Decisions confirmed by the human in conversation: splice replaces the goto flags (reviving the debate rework's option (b)); mini-scenes first, with the generic pool as fallback; Prose pack mode in storyboard rather than a new tool; direct save to the live packs; the three test seams above.
- The `aftermath` slot is reserved for a mid-week/judgement follow-up. It is defined in the schema but the meeting only plays it if a later ticket wires it.
- Fact buckets for the coverage grid come from the thresholds actually used in `when` conditions, not from a hand-kept list.
