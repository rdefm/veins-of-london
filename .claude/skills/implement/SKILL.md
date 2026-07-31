---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work.

Commit your work to the current branch.

Then mark the ticket/issue complete:

- **If the ticket is a markdown file** (a local-markdown tracker ticket, e.g. under `.scratch/`), the final stage is to rename the file, appending `_COMPLETED` to the end of the filename, before the `.md` extension — e.g. `01-districts-data-travel-rule.md` → `01-districts-data-travel-rule_COMPLETED.md`. Use this renamed-file signal instead of (not in addition to) any `Status:` line convention described elsewhere.
- **Otherwise**, follow this repo's tracker convention — see `docs/agents/issue-tracker.md` (referenced from `CLAUDE.md`/`AGENTS.md`'s `## Agent skills` block): the native close/done action for GitHub or GitLab issues, or whatever the "other" tracker's config describes. If no tracker config exists yet, ask rather than guessing or skipping the step.
