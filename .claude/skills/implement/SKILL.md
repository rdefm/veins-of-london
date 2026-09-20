---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

First, check whether the ticket has a **Relevant files** field. If it does, open and read those files/sections directly instead of running a fresh discovery pass (Explore, grepping the codebase, reading CODEMAP.md/REFERENCE.md cover-to-cover). Fall back to normal search for whatever the hints don't cover: the field is absent, a hinted path no longer exists, or a hinted file turns out not to actually cover what the ticket needs. Don't treat a full CODEMAP.md/REFERENCE.md read as a default step — the point is skipping that cost when hints exist and hold up.

When a fallback discovery pass is needed, spawn a fork subagent to run it rather than doing raw Explore/grep in the main thread — a fork inherits full context, and its search noise never has to land in yours. Have it return a compact digest of what the implementation will actually need (e.g. layout constants, a nav-bar gotcha, the test file's live-tree pattern), not a transcript of everything it searched.

Grep named symbols with context lines (`-C`) before Read'ing a file over ~150 lines — don't Read a whole file to locate something inside it.

Prefer the Edit tool over shell one-liners (`sed`, heredocs, PowerShell `-replace`, etc.) for text substitution, even in scratch files.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly. Don't run tests (single files or the full suite) mid-implementation — run them once, at the end, after the whole ticket is implemented.

Once done, use /code-review to review the work.

Commit your work to the current branch. Stage and commit ALL outstanding changes in the working tree (`git add -A`, minus anything gitignored or that looks like a secret) — not just the files touched by this task. Don't leave unrelated changes uncommitted just because they weren't "this task."

Then mark the ticket/issue complete:

- **If the ticket is a markdown file** (a local-markdown tracker ticket, e.g. under `.scratch/`), the final stage is to rename the file, appending `_COMPLETED` to the end of the filename, before the `.md` extension — e.g. `01-districts-data-travel-rule.md` → `01-districts-data-travel-rule_COMPLETED.md`. Use this renamed-file signal instead of (not in addition to) any `Status:` line convention described elsewhere. Commit this rename too — don't leave it dangling in the working tree.
- **Otherwise**, follow the repo's tracker convention — check for a doc like `docs/agents/issue-tracker.md` (often referenced from `CLAUDE.md`/`AGENTS.md`'s `## Agent skills` block): the native close/done action for GitHub or GitLab issues, or whatever the "other" tracker's config describes. If no tracker config exists yet, ask rather than guessing or skipping the step.
