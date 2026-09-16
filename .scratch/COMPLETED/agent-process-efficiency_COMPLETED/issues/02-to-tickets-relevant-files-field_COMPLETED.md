# 02 — `to-tickets` skill: add a "Relevant files" field to the ticket template

**What to build:** The global master `to-tickets` skill writes a **Relevant files** field into every ticket it publishes, populated at ticket-creation time (while `to-tickets` already has the codebase explored in context) — not left for `implement` to rediscover later in a fresh session. The field lists:
- Real file paths the ticket is expected to touch or needs to read (code files, CODEMAP.md rows worth calling out by name if the file's CODEMAP entry is unusually load-bearing)
- Specific `REFERENCE.md` §-section headers when the ticket's mechanics live in a numbered/lettered spec section, so a later `implement` session can grep straight to that section instead of reading the whole file

This reverses the skill's current explicit guidance ("avoid specific file paths... they go stale fast") for this one field — the tradeoff is deliberate: paths captured fresh during exploration are cheaper than re-deriving them from scratch in every downstream fresh-context `implement` session. Keep the "avoid file paths" guidance for prose elsewhere in the ticket (What to build / Acceptance criteria) — only the new field carries paths.

**Relevant files:**
- `~/.claude/skills/to-tickets/SKILL.md` — both `<local-ticket-template>` and `<issue-template>` blocks, plus the closing paragraph that currently says to avoid file paths/snippets (needs a carve-out note for the new field)
- `~/.claude/skills/to-tickets/SKILL.md`'s step 3 ("Draft vertical slices") / step 4 ("Quiz the user") — the presented breakdown format shown to the user should surface Relevant files too, not just title/blocked-by/what-it-delivers

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `<local-ticket-template>` gains a `**Relevant files:**` section (paths, and REFERENCE.md § headers where applicable), positioned near `**Blocked by:**`
- [ ] `<issue-template>` gains an equivalent `## Relevant files` section
- [ ] The closing "avoid specific file paths" paragraph is amended to exclude this new field, with a one-line rationale (captured live during exploration, so it doesn't go stale the way ad hoc in-prose paths do)
- [ ] Step 4's "present the breakdown" list of what to show the user includes Relevant files alongside Title/Blocked by/What it delivers
- [ ] No change to veins-of-london's local copy in this ticket — that's ticket 07 (propagation)
