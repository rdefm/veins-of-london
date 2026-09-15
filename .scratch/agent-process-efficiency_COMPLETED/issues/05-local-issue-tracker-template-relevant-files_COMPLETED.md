# 05 — This repo's local ticket template gets the "Relevant files" field

**What to build:** `docs/agents/issue-tracker.md` (veins-of-london's own local-markdown tracker convention doc) documents the same **Relevant files** field ticket 02 added to the global `to-tickets` skill template, so tickets filed in this repo via `/to-tickets` carry it consistently, and anyone reading `docs/agents/issue-tracker.md` in isolation sees the current ticket shape.

**Relevant files:**
- `docs/agents/issue-tracker.md` — the "## Conventions" section (ticket file shape) and anywhere it describes what a ticket file contains
- `~/.claude/skills/to-tickets/SKILL.md`'s `<local-ticket-template>` (from ticket 02) — copy the field's wording/placement from here so the two stay consistent

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `docs/agents/issue-tracker.md` documents the Relevant files field in the same place/shape it documents `Status:` and `Blocked by:`
- [ ] Wording is consistent with the global `to-tickets` template from ticket 02 (not a divergent re-description)
- [ ] No change to any already-filed ticket files in `.scratch/*/issues/` — this is forward-looking documentation only
