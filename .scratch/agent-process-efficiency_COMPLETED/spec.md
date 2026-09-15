# Agent process efficiency

Grilling session outcome (2026-09-15): refine the grill-me → to-tickets → implement pipeline to cut token usage, since tickets are worked in **fresh Claude Code sessions** (confirmed: one session per ticket, not a continuous session per feature) — meaning any fixed per-session discovery cost gets paid once per ticket, across every repo.

## Findings

- `CODEMAP.md` (58.7KB / ~15k tokens) has drifted from "what's here now" into a permanent ticket-by-ticket changelog baked into individual entries (e.g. `hq_lab_bench.gd`, `combat.gd`, `dial_widget.gd` each narrate 3-6 tickets' worth of history inline). This makes the map itself expensive to read, undercutting its purpose as a cheap lookup.
- `docs/REFERENCE.md` (94.6KB / ~23k tokens) is read in full by implement sessions even when a ticket only touches one formula/table.
- Neither the `to-tickets` nor `implement` skill currently mandates or even mentions CODEMAP.md — `to-tickets` treats codebase exploration as optional, `implement` doesn't reference it at all. Discovery is ad hoc per ticket.
- `to-tickets`'s existing guidance explicitly avoids file paths in tickets ("they go stale fast") — overridden here: `to-tickets` already explores the codebase once while drafting tickets, so capturing file hints then is strictly cheaper than re-discovering them from scratch in every fresh implement session.
- The engineering skills (`to-tickets`, `implement`, `grilling`, etc.) live as git-tracked copies inside each repo's `.claude/skills/`, sourced from a global master at `~/.claude/skills/`, with no sync mechanism — copies have already diverged slightly. Changes must be made at the global master and then manually propagated per repo.

## Decisions

1. CODEMAP.md entries describe current state only — no historical ticket narration. History stays in git log and `_COMPLETED` ticket files, which already preserve it.
2. One-time cleanup pass on the existing file now, not organic drift-based rewriting.
3. Tickets gain a **Relevant files** field: real file/path hints, plus specific `REFERENCE.md` §-section headers when a ticket touches formulas/data. Captured by `to-tickets` at ticket-creation time, while full context is already loaded.
4. `implement` consults a ticket's Relevant files hints first, jumping straight there; falls back to CODEMAP/REFERENCE.md/Explore search only if a hint is missing or turns out stale.
5. Skill changes are made once at the global master (`~/.claude/skills/`) and then copied into every repo under `~/projects` that has its own `.claude/skills/` copy — veins-of-london included — each repo getting its own commit.

## Tickets

See `issues/`. Two independent tracks (CODEMAP hygiene: 01/03/04; Relevant-files hints: 02/05/06) converge at the final rollout ticket (07).
