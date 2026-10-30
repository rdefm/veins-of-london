---
name: implement-storyboard-event
description: Implement / promote an event drafted in the storyboard tool (tools/storyboard.html) — action its open "for Claude" comments and resolve them, convert the branch draft to a flat live event, write data/events/<id>.json, run the tests, report. Use when the user says "implement <event>", "promote <event>", or points at a .scratch/writing-revamp/*-proposal*.md built or edited in the storyboard tool.
---

# Implement a storyboard event

Argument: a proposal file (`.scratch/writing-revamp/<name>-proposal<N>.md`) or an event id. For an id, pick the highest-numbered `*-proposal*.md` whose JSON block has that `id`; if two plausibly match, ask which.

The proposal's first ```json block is a **branch draft** (`.scratch/storyboard-editor/spec.md` § Draft format). All conversion goes through `tools/promote_storyboard.js`, which runs the storyboard tool's own draft model — never hand-convert branches to indexes.

## 0. Pick a lane

```
node tools/promote_storyboard.js comments <proposal.md>
```

- **Fast lane** — zero open comments (typically: the user already promoted from the tool). Skip to § Fast lane below.
- **Full lane** — one or more open comments: § 1 onward, except the full suite defers to commit / end of session (§ 3).

Say which lane in the report.

## Fast lane

No ticket, no commit, no full suite, no doc reads unless a failure needs one. The live file is already written; don't re-promote unless the proposal changed.

```
node tools/test_storyboard.js
godot --headless -s tests/test_runner.gd -- test_event_content_lint.gd
grep -l "<event_id>" tests/test_*.gd
godot --headless -s tests/test_runner.gd -- <each file from the grep, space-separated, minus test_event_content_lint.gd if listed>
```

Select test files by grepping `tests/` for the event id (the `id` in the JSON block / `data/events/<id>.json` name); run only those. If the grep finds none, run just the first two commands.

A failure outside the event's own tests (storyboard JS, lint on a different event, an unrelated test file) is reported to the user with the failing name and message, not fixed in-session. Failures in the event's own lint results or its own test files are fixed in the proposal (see § 3) and re-promoted.

Report: lane, files run, pass/fail counts, out-of-scope failures. Then stop.

## 1. Open comments

```
node tools/promote_storyboard.js comments <proposal.md>
```

One line per open "for Claude" comment: `id <tab> anchor <tab> text`. Anchors read `board`, `branch <name>`, `<branch> · <card key>`, or `... · option N "label" · success`. Notes (kind `note`) aren't listed: they are memory, not instructions — don't action them.

Action each comment by editing the draft inside the proposal's JSON block (Edit tool, not a rewrite of the file):

- Prose changes follow `docs/CONTENT-GUIDE.md` §3 tone bible — one dry line per threat, nothing winking at the camera. New or changed lines are draft prose: list the file under `PROSE-REVIEW:` in the report.
- Mechanics (checks, effects, flags, paths, conditions) follow `docs/REFERENCE.md` §3.9a Event choice checks and the condition vocabulary there. Every number comes from the spec or the comment — never invent one.
- Routing stays in draft form: `goto: {branch, card?}` on outcomes or cards, branch `then`. Keep card `key`s; give a new card a key no other card uses. No loops except a hub: a `goto` back to an earlier `choice` card (options are one-shot unless `reselectable: true`); the hub needs an option that leaves the loop. Flag that option `exit: true` (the footer →; promote refuses a hub with none) and set the hub card's `advance` (`"anytime"` default, `"all"`, or N) for when → shows; both pass through promote unchanged.
- A comment that asks for a design decision the specs don't make, or that you can't action as written: leave it open and ask the user. Don't promote with it open.

Then resolve what you actioned (writes the status back into the JSON block):

```
node tools/promote_storyboard.js resolve <proposal.md> <id> [<id>...]
```

## 2. Promote

```
node tools/promote_storyboard.js promote <proposal.md>
```

Writes `data/events/<id>.json` (house formatting), refusing while open comments remain. It lays branches out in topological order (start first, every jump forward except hub back-edges, which become backward gotos), maps `{branch, card}` to card indexes (or to card `key`s when the draft carries `"_keyLinks": true`, set on import of a live event that already uses key links), turns card gotos / branch `then`s into card `goto` / conditional `goto` / `end: true`, and strips keys, `checkNote`s, branch titles and `_comments`. It prints any cards no path reaches — they're left out; tell the user which.

If it refuses:

- `play can loop` — the draft has a cycle that isn't a hub (a back-edge to a choice card); tell the user, don't break it yourself.
- `hub has no forward exit` — every option of that hub loops back or is hidden after use; tell the user, don't break it yourself.
- `conditional then that can end the event` — the engine's conditional goto has no "end" entry and falls through on no match. Ask the user which branch the else / ending entry should go to.
- A target error (`unknown branch`, `no card`, `branch X has no cards`) — a dangling link; ask the user where it should go.

The storyboard tool's **Promote** button writes the same file (same code, byte-identical); if the user already promoted from the tool, skip straight to the diff check and tests.

`git diff data/events/<id>.json` — when overwriting a live event, check the diff is only what the draft changed. Re-check every `image` path still exists.

## 3. Tests

```
node tools/test_storyboard.js
godot --headless -s tests/test_runner.gd -- test_event_content_lint.gd
```

Full lane: the full suite (`scripts/run_tests.sh > <scratchpad>/tests.log 2>&1; grep -E "FAIL|ERROR" <scratchpad>/tests.log`) runs at commit / end of session, not after each promote. Under /implement that is the final step before committing.

Content lint failures (unknown flags/tokens, block words vs `at`, bad gotos) get fixed **in the proposal**, then promote again — the live file is always a promote output, never hand-edited. A lint "known list" entry is only for something the user confirms is intended.

## 4. Report

Short, per the user's concision rule:

- written / overwritten file, card count, left-out cards
- comments resolved (id → one-line what changed); comments left open and why
- test result (counts)
- `PROSE-REVIEW:` the proposal file, if any prose was written or changed

Don't commit unless the user asked (or this is running under /implement, which commits).
