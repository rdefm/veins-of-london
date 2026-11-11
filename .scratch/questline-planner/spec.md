# Questline planner — spec

Status: ready-for-agent

All decisions here come from the 2026-11-11 interview. This spec is phase 1 of the merged quest tooling. The mechanics editor and game quest system stay in `.scratch/quest-editor/spec.md`, which now builds on this one.

## Problem Statement

The author has no way to map a questline (e.g. Collective Act 2) as a whole: which quests it has, in what order, where it branches, which event each quest uses, and how far each quest's writing, choices, observations and art have got. That picture lives in their head, scattered notes and event file names. The storyboard tool, which owns events, only runs in desktop Chrome/Edge, so nothing can be planned from a phone. The planned Quests tab (quest-editor spec) is mechanics-first, desktop-only, and keeps existing questlines read-only, so it can't plan the partly built questlines the author is working on now.

## Solution

The storyboard tool gets a Quests tab that starts as a **questline planner**. It's designed for phones as well as the laptop, and works over the home wifi through a small local server that the laptop runs.

The author picks or creates a questline (one act, e.g. "Collective Act 2"), sees its quests as an auto-laid-out top-to-bottom map with parallel and either/or branches, and adds or rewires quests from a quest sheet. Tapping a quest shows its title, id, summary, events (live, draft or planned), flow, mechanics state, four per-quest statuses and notes. Planned events can become storyboard drafts in one tap. Planning edits autosave and are safe against the other device overwriting them.

Existing questlines are seeded once from game data, so planning starts from what's already built. Quest mechanics (unlock, start, targets, outcomes) come later, in the same tab, per the quest-editor spec. That spec now takes its quest ids and order from this one.

## User Stories

**Access and running**

1. As the author, I want to start the storyboard server with one command or a double-click, so that I can use the tool without setup each time.
2. As the author, I want the server to print a laptop URL, a LAN URL and a QR code, so that I can open the tool on my phone quickly.
3. As the author, I want the phone to remember its access token after the first visit, so that I don't paste it every time.
4. As the author, I want other devices on my wifi refused unless they have the token, so that nothing else can write to my repo.
5. As the author, I want the laptop to keep working with the existing folder picker, so that I can still use the tool without the server.
6. As the author, I want the whole storyboard (all tabs) to load and save through the server, so that phone use doesn't break other tabs, even though only the Quests tab is designed for phones.
7. As the author, I want the server to need nothing beyond Node, so that there's nothing to install.

**Questlines**

8. As the author, I want a questline to be one act (e.g. "Collective Act 2"), so that I plan in the units I think in and maps stay small.
9. As the author, I want to create a questline with a name, an auto-made id, its ToDo page, its act order on that page, a one-line premise and notes, so that it's placed correctly in the game's structure.
10. As the author, I want to pick an existing ToDo page (tutorial, collective, business_empire) or name a new one, so that several acts can share a page.
11. As the author, I want the Quests tab to open on a list of questlines grouped by ToDo page, so that I can find the one I need.
12. As the author, I want each questline row to show its quest count and per-category status roll-ups, so that I can see progress without opening it.
13. As the author, I want the last-opened questline remembered, so that I land back where I was.
14. As the author, I want to rename a questline or edit its premise and notes, so that I can reorganise as the story changes.
15. As the author, I want to delete a questline that has no data-driven quests, so that abandoned plans don't clutter the list.

**The map**

16. As the author, I want a questline's quests shown top to bottom in follow order, so that I can read the act like a timeline.
17. As the author, I want branches laid out side by side and converging quests joined below them, so that I can see structure at a glance.
18. As the author, I want the map laid out automatically on every device, so that I never drag nodes and the phone and laptop show the same picture.
19. As the author, I want a wide map to scroll horizontally inside the map only, so that the page itself never side-scrolls on my phone.
20. As the author, I want parallel branches drawn as solid edges and either/or branches drawn as a labelled fork, so that I can tell "both" from "one or the other".
21. As the author, I want a marker on an edge whose quest has gating beyond its follows-links, so that I know the map isn't the whole unlock story.
22. As the author, I want each node to show its title, a state badge (placeholder, hard-coded, data-driven), four status pips and its first event id (plus a count of others), so that the map is useful without tapping.
23. As the author, I want a quest that follows a quest in another questline to show a "from <questline> ▸" stub at the top, so that cross-act links stay visible.
24. As the author, I want to tap a stub to jump to that questline, so that I can follow the story across acts.
25. As the author, I want a map toolbar with the questline name, roll-ups and "+ Quest", so that the main actions are always to hand.
26. As the author, I want a filter that highlights quests where a chosen category isn't done, so that I can find what still needs art or writing.

**Adding and rewiring quests**

27. As the author, I want "+ Quest" in the questline header to add a root quest with no predecessor, so that I can start a questline or a new thread.
28. As the author, I want "+ Next" on a quest sheet to add a quest that follows it, so that I can extend a chain in one tap.
29. As the author, I want "+ Branch" to add another follower and ask whether it's parallel or a choice, with an optional choice label, so that I can plot forks.
30. As the author, I want "Follows…" to edit which quests a quest follows, with multi-select, so that I can converge storylines or reorder.
31. As the author, I want "Insert after" and "Insert before", so that I can splice a quest into a chain without rewiring by hand.
32. As the author, I want deleting a quest to reattach its followers to its predecessors, so that the chain doesn't break.
33. As the author, I want to be warned before deleting a quest that has mechanics or linked drafts, so that I don't lose real work by accident.
34. As the author, I want a follows-link to be the same thing that later becomes the quest's unlock condition, so that planning is never redone when mechanics arrive.
35. As the author, I want to be stopped from creating a follow loop, so that the questline always has a clear order.
36. As the author, I want to edit a choice edge's label or switch it between parallel and choice, so that I can refine forks as the story settles.

**The quest sheet**

37. As the author, I want tapping a node to open a bottom sheet on my phone and a side panel on my laptop, so that the map stays in place behind it.
38. As the author, I want to close the phone sheet by swiping down or tapping ✕, so that it feels native.
39. As the author, I want to edit a quest's title, so that names can evolve.
40. As the author, I want a quest id made from its title and editable until the quest has mechanics or linked events, so that ids are tidy but stable once things depend on them.
41. As the author, I want a one-to-three-line summary of what happens, so that I can remember each quest's purpose.
42. As the author, I want the sheet to show what the quest follows and what follows it, with choice labels, so that I can see its place in the act.
43. As the author, I want the sheet to show the mechanics state (placeholder, hard-coded, data-driven) and, for hard-coded quests, the linked objective id, so that I know what exists in the game.
44. As the author, I want free-text notes on each quest, so that I can capture ideas and open questions.

**Events**

45. As the author, I want a quest to list several events, so that a quest made of a meet, a middle and a done scene is planned as it's really built.
46. As the author, I want each event entry to show whether it's live, a draft or only planned, so that I can see what's been written.
47. As the author, I want to add a planned event by name or id before it exists, so that I can rough out "a meet scene goes here".
48. As the author, I want to pick live events and storyboard drafts from a list, so that I can't mistype an id.
49. As the author, I want to tap an event entry to open it in the storyboard, so that I can move from plan to writing.
50. As the author, I want a "Create draft" button on a planned event, so that a new storyboard board is made with that id and title and the entry becomes a draft.
51. As the author, I want to reorder and remove event entries, so that the list matches the quest's flow.
52. As the author, I want an entry whose live event or draft no longer exists to be flagged, so that stale links are obvious.

**Statuses**

53. As the author, I want four per-quest statuses (Writing, Choices, Observations, Art), so that I can track production at a glance.
54. As the author, I want each status to be one of n/a, todo, doing, review or done, so that progress is consistent across categories.
55. As the author, I want to tap a status to cycle it and long-press to pick a value, so that updating on my phone is quick.
56. As the author, I want the category list kept in one config list, so that adding a category like Playtest is a one-line edit with no code change.
57. As the author, I want roll-ups per category on the questline header (e.g. Art 3/9 done), so that I know how far the act has got.

**Saving and safety**

58. As the author, I want planning edits to save automatically about a second after each change, so that I never lose work on my phone.
59. As the author, I want a save refused with "Changed elsewhere: reload" if the file changed since I loaded it, so that my phone and laptop never silently overwrite each other or Claude.
60. As the author, I want the refused edit shown so that I can redo it after reloading, so that I lose at most that one change.
61. As the author, I want undo for planning edits within a session, so that I can back out mistakes.
62. As the author, I want a visible saving / saved / error indicator, so that I trust that autosave worked.
63. As the author, I want the tool to pick up changes made on disk when it regains focus, so that edits from another device or Claude show up.

**Existing questlines**

64. As the author, I want Tutorial, Collective Act 1, Collective Act 2 and Business Act 1 pre-filled from the game's existing objectives and events, so that I plan from what already exists.
65. As the author, I want seeded quests marked hard-coded and linked to their objective id and events, so that I know they're already in the game.
66. As the author, I want hard-coded quests to be fully editable for planning (title, flow, events, statuses, notes), so that partly built acts can be planned.
67. As the author, I want hard-coded mechanics shown read-only, so that I can't break shipped behaviour from the planner.
68. As the author, I want to fix the seeded order and branches by hand, so that the guessed first draft becomes accurate.

**Phone experience**

69. As the author, I want the Quests tab readable and usable at phone width with no page side-scroll, so that I can plan away from the desk.
70. As the author, I want touch targets big enough for a thumb, so that I don't mis-tap nodes or statuses.
71. As the author, I want the tool to follow light and dark mode like the rest of the storyboard, so that it's comfortable in the evening.

## Implementation Decisions

**Merge, not a new tool**

- The planner is the storyboard's Quests tab. There's no separate tool. The quest-editor spec's mechanics editor lands in the same tab later and reads the same quest ids and follows-links.

**Storage interface and server mode**

- Storyboard file access goes behind one small storage interface: read text, read JSON, write file, list directory, plus a version token (content hash) per read and a version-checked write. The existing folder-access helpers become the folder-picker backend of that interface.
- Two backends, picked at startup: the folder picker (unchanged behaviour on desktop Chrome/Edge) and server mode (used whenever the page is served by the storyboard server). All tabs use the interface, so every tab works in server mode. Only the Quests tab is designed for phones.
- The server is a plain-Node, dependency-free script with a double-click Windows launcher. It serves the tools folder and a small file API over the repo, listens on the home LAN on a fixed port, and prints laptop and LAN URLs plus a terminal QR code.
- Access needs a random token issued at server start and carried in the printed URL. The page stores it after the first visit and sends it on every API call. Calls without it are refused.
- Writes are limited to the folders storyboard already writes (`.scratch/`, `data/events/`, `data/quests/`, `assets/events/`). Writes and deletes outside them are refused. Reads cover the repo, since the tool reads game data such as objectives and the ToDo pages.
- The server reports file versions (content hash) on read and refuses a write whose expected version doesn't match the file on disk.
- Whether to retire the folder picker for server-only is deferred until the planner is in use.

**Planning data**

- One planning file per questline (act) under a new `.scratch/questlines/` folder. Tool-only: the game never loads it.
- Questline fields: id, name, ToDo page id, act order on that page, premise, notes, status category list, quests.
- Quest fields: id, title, summary, notes, follows (list of quest ids, which may name quests in other questlines), per-follow edge kind (`parallel` or `choice`) and optional choice label, events, statuses, mechanics state, and an objective id when hard-coded.
- Mechanics state is one of `placeholder` (planning only), `hardcoded` (exists in game code, mechanics read-only) and `data` (has a game quest file entry, edited by the mechanics editor later).
- Event entries: id, title, state (`live` if a file exists in `data/events/`, `draft` if a storyboard draft exists, `planned` otherwise), and a later-use flag for "fires on start". State is computed on load, never trusted from the file.
- Status categories live in the planning file's config list, with default Writing, Choices, Observations, Art. Values: `na`, `todo`, `doing`, `review`, `done`. There's no in-tool category editor.
- Placeholder quests never reach game data. When mechanics arrive (quest-editor spec), the game file under `data/quests/` holds mechanics only, and the tool writes each data-driven quest's unlock from its follows-links (quest X complete), ANDed with any extra gating. Structure is owned by the planning file.
- Cross-questline follows are allowed and drawn as stubs. A follow loop within or across questlines is refused.
- Quest ids are unique across all questlines. An id is editable until the quest has mechanics or a draft/live event, then fixed.

**Planning model (pure)**

- A pure, marker-delimited planning-model section inside the storyboard HTML, like the draft model. It has no DOM or storage access.
- Operations: parse/serialise and validate a planning file; add root, add next, add branch (with kind/label), insert before/after, delete with reattach to predecessors, set follows, set edge kind/label, rename/re-id quest (with the fixed-id rule), add/reorder/remove event entries, set status, cycle status; loop detection; auto-layout layering (layer from longest follows path; branches side by side; choice forks marked); status roll-ups and the "category not done" filter; resolve event states from a provided list of live ids and draft ids; validate against provided objective ids and event lists.
- Undo uses the storyboard's existing history helper pattern over planning-model snapshots.

**Quests tab UI**

- Landing: questline list grouped by ToDo page, rows with quest count and roll-ups, "+ Questline". Last-opened questline remembered in browser storage (convenience only).
- Map: auto-layout top to bottom, rendered as inline SVG/HTML. Horizontal scroll inside the map container only. Nodes show title, state badge (◌ placeholder, ⚙ hard-coded, ● data-driven), four pips and the first event id plus a "+N" count. Edges: solid for parallel, forked/dashed with label for choice, ⚙ marker for extra gating. Toolbar: name, roll-ups, "+ Quest", category-not-done filter.
- Sheet: bottom sheet on phone width, side panel on wide screens. Order: title + id, summary, events, flow (follows / followed by, with actions + Next, + Branch, Follows…, Insert after/before, Delete), mechanics state (with objective id or a jump to the mechanics editor once it exists), statuses, notes.
- "Create draft" on a planned event reuses the storyboard's new-board flow with that id and title.
- Autosave about 1s after each planning edit through the version-checked write. On refusal, show "Changed elsewhere: reload" with the unsaved change described. Saving/saved/error indicator. Reload on window focus, as the storyboard already does.
- Follows the storyboard's existing palette tokens and light/dark handling.

**Seed**

- A one-time seed is written as part of the build: planning files for Tutorial, Collective Act 1, Collective Act 2 and Business Act 1, built from `objectives.json`, `data/events/`, existing storyboard drafts and `todo.json`'s questline pages. Quests are marked hard-coded with objective ids and events, and order is guessed from objective order and event naming. Statuses start at `todo`, or `na` where obvious.
- No re-runnable importer.

## Testing Decisions

Good tests assert external behaviour through the highest seam: given a planning file and inputs, what the author would see after an operation, or what the server returns for a request. They don't assert private helpers or internal shapes.

Seams:

1. **Planning model:** Node tests that extract the pure planning-model section from the shipped HTML, exactly as `tools/test_storyboard.js` does for the draft model. Cover: round trip; each add/insert/delete/follows operation including reattach and loop refusal; edge kinds and labels; fixed-id rule; auto-layout layers for chains, parallel forks, choice forks and converges; roll-ups and filter; event state resolution, including stale entries; validation against objective and event id lists. The same file also validates every committed planning file under `.scratch/questlines/` (seed and later edits) against the model and the real objective/event ids.
2. **Server:** a Node test that starts the server on a random port and drives it over HTTP: serve page, read/list/write, token required, writes outside the whitelist refused, stale-version write refused, current-version write accepted.

Human-checked: the folder-picker backend, the phone layout and touch interactions, and all tabs still loading and saving in server mode. Godot tests are unaffected, since there's no game code change in this spec.

## Out of Scope

- Quest mechanics: unlock conditions beyond follows-links, start routes, targets, deadlines, outcomes, the shared flag picker, quest lint, and the game `Quests` system. All of it stays in the quest-editor spec, which builds on this one.
- Converting hard-coded questlines to data-driven ones.
- Writing any game data, including new ToDo pages (presentation stays in the quest-editor spec's mechanics part).
- Phone-friendly design of storyboard tabs other than Quests.
- Access away from home, offline use, export/import, and syncing via Claude or a hosted service.
- Manual node positioning.
- Per-event statuses, characters, and district fields on quests.
- An in-tool editor for status categories.
- Retiring the folder picker (to be re-evaluated once the planner is live).
- `tools/quest-editor-mobile.html` stays retired.

## Further Notes

- `.scratch/` is tracked in the public GitHub repo, so planning files (including notes) are public once committed.
- The storyboard skills (`event-storyboard`, `implement-storyboard-event`, `plate-compositor`) should mention that server mode exists, but don't need changes to work.
- CODEMAP.md needs rows for the server script, its launcher and the `.scratch/questlines/` planning files. The storyboard row should mention the storage interface and the Quests tab.
- A storyboard draft's id is the event id, so "Create draft" uses the planned event's id as the board id.
