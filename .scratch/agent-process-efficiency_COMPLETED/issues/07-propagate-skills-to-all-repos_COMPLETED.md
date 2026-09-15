# 07 — Propagate updated skills to every repo

**What to build:** The updated `to-tickets` and `implement` SKILL.md files (global master at `~/.claude/skills/`, updated by tickets 02 and 06) are copied into every repo under `~/projects` that has its own `.claude/skills/` copy of either skill — veins-of-london included — each repo getting its own commit. This is the final ticket: it's the point where the process-efficiency work actually takes effect everywhere, not just at the global master.

**Relevant files:**
- `~/.claude/skills/to-tickets/SKILL.md`, `~/.claude/skills/implement/SKILL.md` — the updated source of truth
- Every `<repo>/.claude/skills/to-tickets/SKILL.md` and `<repo>/.claude/skills/implement/SKILL.md` under `~/projects` — enumerate with something like `find ~/projects -path "*/.claude/skills/to-tickets/SKILL.md" -o -path "*/.claude/skills/implement/SKILL.md"`
- Note from the grilling session: veins-of-london's copy had already diverged slightly from the global master before this work started (one line of wording difference in `implement`'s "Otherwise" bullet) — when copying, take the global master's content wholesale rather than trying to merge the old repo-local wording back in, unless that repo-local wording encoded a real repo-specific decision worth preserving (check before overwriting)

**Blocked by:** 02, 06

**Status:** ready-for-agent

- [ ] Every repo under `~/projects` with its own `.claude/skills/to-tickets/` and/or `.claude/skills/implement/` folder has the updated SKILL.md copied in
- [ ] veins-of-london's own `.claude/skills/to-tickets/SKILL.md` and `.claude/skills/implement/SKILL.md` are updated and committed as part of this ticket (not left as the stale pre-existing copies)
- [ ] Each repo's update is its own commit, scoped to that repo
- [ ] Any repo-local wording divergence found during the copy is either intentionally dropped (global master wins) or flagged to the human if it looks like a real repo-specific decision — not silently lost without a note
