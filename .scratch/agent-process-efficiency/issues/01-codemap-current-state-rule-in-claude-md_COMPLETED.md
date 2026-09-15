# 01 — Codify the current-state-only CODEMAP rule in CLAUDE.md

**What to build:** `CLAUDE.md`'s workflow step 7 (the "update CODEMAP.md in the same commit" rule) explicitly states that CODEMAP entries describe **current state only** — what a file does now, in ~1-2 sentences — never a running log of which ticket did what. History belongs in git log and `_COMPLETED` ticket files under `.scratch/`, which already preserve it; CODEMAP is a cheap lookup table, not a changelog.

**Relevant files:**
- `CLAUDE.md` — workflow step 7, in the "## Workflow — every task, no exceptions" section
- `CODEMAP.md` — read a couple of entries (e.g. `hq_lab_bench.gd` under `scenes/screens/*.gd`, `combat_prototype.gd` under `systems/*.gd`) as the "don't do this" example to calibrate what "current-state only" should look like

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Step 7 (or a new adjacent bullet) states: CODEMAP entries are current-state descriptions, not historical narration; no ticket numbers, no "ticket X did Y then ticket Z did W" sequences
- [ ] Rule notes where history actually lives instead (git log / `_COMPLETED` ticket files), so the discipline doesn't read as "history is discarded"
- [ ] Change is a documentation-only edit to CLAUDE.md — no CODEMAP.md rewriting happens in this ticket (that's 03/04)
