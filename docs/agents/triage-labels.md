# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`              | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`                | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`           | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`           | `ready-for-human`    | Requires human implementation            |
| `wontfix`                   | `wontfix`            | Will not be actioned                     |

This repo's tracker is local markdown (see `issue-tracker.md`), so these are recorded as a `Status:` line near the top of each ticket file rather than a native tracker label.

**Repo-specific addition — completion:** not one of the five canonical roles (they're pre-work routing only). A ticket whose work has landed and been committed is marked done by appending `_COMPLETED` to its filename (before the `.md` extension), not by a `Status:` line. See "Completion" in `issue-tracker.md`.
