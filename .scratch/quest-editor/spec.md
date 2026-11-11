# Quest editor — spec

Status: ready-for-agent

All decisions here came from, or were approved in, the 2026-11-06 interview.

## Amendment (2026-11-11): builds on the questline planner

This spec is now phase 2 of the merged quest tooling. Phase 1 is `.scratch/questline-planner/spec.md` and must land first. Where the two conflict, the planner spec wins:

- **Questline = one act**, e.g. "Collective Act 2", referencing a ToDo page id. ToDo page presentation (label, subtitle, accent, done flag) is a separate page entity edited here, and several acts can share a page.
- **Structure lives in the planner's files** under `.scratch/questlines/`: quest ids, titles, follows-links, parallel/choice edges, events, statuses, notes. Game quest files hold mechanics only. On save, a data-driven quest's unlock is written from its follows-links ANDed with any extra gating. Story 8 ("unlocks after quest X") is the follows-link.
- **Auto-layout flowchart, no manual positions.** Story 10 and "flowchart positions as editor-only data" are dropped.
- **Existing questlines aren't read-only.** Their planning is editable from phase 1, and only their hard-coded mechanics are read-only until converted.
- **Placeholder quests** exist only in planning files and never reach game data or quest lint.
- **Storage** goes through the planner's storage interface, so the mechanics editor works in both folder-picker and server mode. Phone authoring of mechanics is still out of scope, but the tab must not break at phone width.

## Problem Statement

New questlines can't be created without Claude. Quests live partly in objectives data and partly in hard-coded scripts, so authoring one means editing code: its goals, how it unlocks, how the player starts it, and what happens at the end. Setting flags from player choices or quest results also relies on typing exact names, and a typo fails silently.

## Solution

A Quests tab in the storyboard tool. The author creates a questline, adds quests, connects them on a flowchart, and sets each quest's unlock condition, start route, targets and outcomes. Events stay authored in the storyboard, and quests link to them.

A new data-driven quest system runs the result in-game with no code change. Both the Quests tab and event editing share one flag picker, so flags can be set from player choices, outcomes and quest completion. Existing questlines appear read-only at first, so their flags and goals can be reused, and convert to editable in a later phase.

## User Stories

**Questlines**

1. As an author, I want to create a questline with a name, subtitle and accent colour, so that it appears as its own page in the player's ToDo.
2. As an author, I want to edit or delete a questline, so that I can reorganise story work.
3. As an author, I want a flag that marks a whole questline done, so that its ToDo page finishes correctly.
4. As an author, I want a list of all questlines, so that I can find the one I need.

**Quests and structure**

5. As an author, I want to add quests to a questline, so that I can build it up in pieces.
6. As an author, I want each quest to have a title, detail text and ToDo presentation, so that the player knows what to do.
7. As an author, I want the questline shown as a flowchart, so that I can see chains, branches and parallel quests.
8. As an author, I want a one-click "unlocks after quest X" link, so that common chains don't need a hand-written condition.
9. As an author, I want a quest to depend on several earlier quests, so that storylines can converge.
10. As an author, I want to arrange flowchart nodes, so that large questlines stay readable.

**Unlock conditions**

11. As an author, I want a quest unlocked by a flag being true or false, so that player choices can gate it.
12. As an author, I want to combine conditions with AND/OR, so that I can express real story gates.
13. As an author, I want to use existing condition kinds such as recipe known or staff skill, so that quests can react to game progress.
14. As an author, I want an always-available quest, so that a questline can open at game start.

**Start routes**

15. As an author, I want a quest to auto-start on unlock, so that story can move on by itself.
16. As an author, I want an auto-started quest to be able to fire an event immediately, so that it can open with a scene.
17. As an author, I want a chosen contact to send text that starts the quest, so that it feels part of the phone.
18. As an author, I want optional reply buttons on that text, so that the player can accept or decline.
19. As an author, I want a ToDo or BizBrief row that starts the quest, so that the player can begin when ready.
20. As an author, I want a map pin or district action that starts the quest, so that it can be tied to a place.
21. As an author, I want any start route to optionally fire a chosen event, so that a quest can begin with a scene.
22. As an author, I want to pick events and contacts from lists, so that I can't reference something that doesn't exist.
23. As an author, I want to jump from a quest to its event in the storyboard, so that I can move between them.

**Targets**

24. As an author, I want a picker of every goal type the game supports, so that I can use them without knowing their schema.
25. As an author, I want typed fields per goal type, so that I enter valid parameters.
26. As an author, I want to combine targets with "all of" or "any of", so that a quest can have alternative solutions.
27. As an author, I want progress text for a target, so that ToDo shows how far along the player is.
28. As an author, I want a flag as a target, so that an unusual condition can be set from an event.
29. As a player, I want ToDo to show my active quest and its progress, so that I know what to do next.

**Outcomes and failure**

30. As an author, I want completing a quest to set flags, so that it can unlock other quests.
31. As an author, I want completing a quest to fire an event or contact text, so that a result has a story beat.
32. As an author, I want to grant cash, ore, items, relation or XP, so that quests pay out with no code.
33. As an author, I want a deadline on a quest, so that it can be failed by time.
34. As an author, I want a fail condition, so that a quest can be lost by a story turn.
35. As an author, I want separate failure outcomes, so that failing has its own consequences.
36. As a player, I want a failed quest clearly marked, so that I know the chance has gone.

**Flags**

37. As an author, I want one searchable flag list in both the Quests tab and the event editor, so that I use existing names correctly.
38. As an author, I want to see where each flag is set and read, so that I understand a change before making it.
39. As an author, I want to explicitly create a new flag, so that a typo can't create one by accident.
40. As an author, I want to set flags from a player choice, so that decisions can gate later quests.
41. As an author, I want to set flags from a check's success or failure, so that outcomes can gate later quests.
42. As an author, I want to set flags on event completion, so that finishing a scene can gate later quests.
43. As an author, I want a warning for a flag read but never set, or set but never read, so that broken gates show up before release.

**Existing questlines and safety**

44. As an author, I want to see existing questlines read-only, so that I can tie new quests to them.
45. As an author, I want to pick existing quest flags and goals as unlocks, so that new work can follow old story.
46. As an author, I want a saved quest checked for broken references, so that I can't ship one that can't start or finish.
47. As an author, I want a warning for a quest that can never unlock, so that I can fix a dead gate.
48. As an author, I want to save directly to the game's quest data, so that I don't need Claude to wire it in.
49. As a player with an older save, I want new quests to work after an update, so that I needn't start again.
50. As a player, I want a rewind or reload to restore quest state, so that it matches the rest of the game.

## Implementation Decisions

**Quest data**

- New quest content lives in its own data directory, one file per questline, auto-discovered at boot like events. No id list to maintain. All content is data.
- A questline holds its ToDo presentation (label, subtitle, accent, done flag) and its quests.
- A quest holds identity and display text, `unlock`, `start`, `targets`, optional `deadlineDays` and `failIf`, `onComplete`, `onFail`, and flowchart positions as editor-only data.

**Quest system (game)**

- A new `Quests` system of static functions, following the one-way data flow: it reads and writes the pure data tree and never touches Nodes.
- Each quest moves through one lifecycle: locked → available → active → complete or failed. Runtime state lives in a new top-level `quests` entry in the state tree, as plain data, so saves and Rewind cover it. Old saves receive it through the existing top-level default backfill.
- Targets run through the existing Objectives evaluator, which already evaluates generated definitions, so all goal types are shared. "Any of" needs adding beside the existing "all of".
- Unlock and fail use the existing condition vocabulary. Flag and any-of kinds are added if absent.
- Quests evaluate at the same action boundaries as `Objectives.refresh()`, plus day rollover for deadlines.
- Completing or failing a quest applies its outcomes through the existing event effects engine, so rewards and flags use the same ops as events.
- Every quest gets generated complete and failed flags, visible in the flag list, so other quests and events can gate on them without authoring extra flags.
- An available quest stays available until started; a player's declined reply leaves it available.
- A deadline counts from when a quest goes active.

**Start routes**

- Four routes, per quest: auto, contact text, ToDo/BizBrief row, map pin. Each can fire an optional event.
- Contact text uses the existing pending-message mechanism, with a new kind for quest offers and optional replies.
- ToDo and BizBrief use the existing ToDo projection and Daily Brief actions. New questlines add pages from quest data.
- Map pins reuse the existing event pin behaviour and its flag gates.

**Storyboard tool**

- A Quests tab inside the storyboard tool, with no separate tool. Quest logic sits in a pure model section or separate script, so it can run in Node tests like the draft model, and the UI stays thin.
- The tab saves directly to quest data files, with Save and Undo like event editing.
- The flowchart reuses the storyboard's existing graph approach.
- The existing condition builder is shared for unlock and fail conditions. Effects editors are shared for outcomes.
- A shared flag picker replaces flag text fields in the event editor and Quests tab: search, used-by list, explicit Create flag. It builds its list from a scan of events, quest data and exported reference data.
- `tools/quest-editor-mobile.html` is retired and isn't extended.

**Lint**

- Lint runs in both JS (tool) and GDScript (tests), like event lint: unknown events, contacts, flags and goal types; a flag read but never set, or set but never read; a quest that can't unlock; a target that can't complete.
- Errors block Save only where the quest could break play. Unknown references block; read-never-set warnings don't, since a flag can be set by code the scan misses.

**Phases**

- Phase 1: new quests, editor, flags, read-only view of existing questlines.
- Phase 2 (separate spec or tickets): convert existing questlines to the data-driven form. This needs replay testing and removal of hard-coded triggers.

## Testing Decisions

Good tests assert external behaviour through the highest seam: given quest data and game state, what the player would see and get. They don't assert private helpers or internal state shape.

Seams:

1. **Game:** a test file for the quest system that loads fixture quests and drives state: unlock → start → targets → complete or fail → outcomes, covering each start route, deadlines, save/load and old-save backfill. Prior art: `test_objectives`-style tests and the event content tests.
2. **Tool:** pure quest and flag model tests run in Node with the storyboard's test file: round trip of a questline, flowchart links to unlock conditions, flag scan and Create flag. Prior art: storyboard draft-model tests.
3. **Lint:** the JS and GDScript quest lints agree on the same fixtures. Prior art: the event content lint and its JS mirror via exported reference data.

UI is human-checked. Screens stay free of state changes, and test hygiene rules apply: cap any loop, set state directly.

## Out of Scope

- Editing event cards in the Quests tab: the storyboard's event editor does that.
- Converting existing questlines in phase 1: they're read-only.
- New goal or condition types beyond what's needed for flags and any-of. A new goal type still needs code.
- New gameplay rewards: outcomes use existing ops.
- Phone authoring and the mobile quest tool.
- Quest journal or new player-facing screens beyond ToDo, BizBrief, phone and map.

## Further Notes

- Works best after the storyboard-safe-promote tickets, which make card references and trigger fields safe. The shared flag picker should be built once and reused by that folder's Triggers panel.
- Whether to delete `tools/quest-editor-mobile.html` is undecided: it shares a code section with the storyboard and has its own tests.
- Every new player-facing string needs the `PROSE-REVIEW:` flag if drafted by Claude; author-written quest text doesn't.
- REFERENCE.md, CONTEXT.md and CODEMAP.md need updating as the system lands. A new `Quest` glossary entry should distinguish it from an Objective.
