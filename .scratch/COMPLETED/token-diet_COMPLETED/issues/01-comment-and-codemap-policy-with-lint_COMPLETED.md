# 01 — Comment + CODEMAP policy with lint

**What to build:** The project constitution states a comment policy — comments describe what code does *now*, cite spec/vision § headers for rationale, and never narrate ticket numbers, what a thing "used to" be, or what was deleted — and a hard per-row length cap for CODEMAP. A lint script enforces both and runs as part of the whole-project check, failing on any CODEMAP row over the cap and on any GDScript comment line matching the history vocabulary (ticket numbers, "used to", "no longer", "previously", "old X", "deleted", "removed", "renamed"). Files that currently violate are listed in an allowlist the strip tickets shrink to empty; the lint never passes a *new* violation outside that list.

**Blocked by:** None — can start immediately.

**Relevant files:** `CLAUDE.md` (Workflow step 7 — add the comment-policy rule beside it), `scripts/check_all.sh`, new `scripts/lint_tokens.sh` (+ the allowlist file it reads), `CODEMAP.md`, `docs/agents/issue-tracker.md` (read only, for the "current state only" precedent).

**Status:** ready-for-agent

- [ ] CLAUDE.md carries the comment policy and the CODEMAP row cap in one short block; no other CLAUDE.md content changes.
- [ ] Running the whole-project check runs the lint; lint exits non-zero on a CODEMAP row over the cap or a non-allowlisted history-vocabulary comment line, and prints file:line for each.
- [ ] Allowlist seeded with every file that violates today so the check is green immediately; adding a fresh violation to a non-allowlisted file makes it red (demonstrated, then reverted).
- [ ] Lint runs with plain bash + grep/awk — no godot needed, sub-second.
