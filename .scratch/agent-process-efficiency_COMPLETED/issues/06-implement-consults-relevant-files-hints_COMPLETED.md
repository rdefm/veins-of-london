# 06 — `implement` skill: consult ticket hints before searching

**What to build:** The global master `implement` skill reads a ticket's **Relevant files** field (added in ticket 02) as its first move, and opens/reads those files and REFERENCE.md sections directly instead of running a fresh Explore/grep discovery pass. Falls back to searching CODEMAP.md/REFERENCE.md/the codebase generally only when: the field is absent (older ticket, predates this change), a hinted path no longer exists, or the hinted file turns out not to actually cover what the ticket needs (staleness).

This is the other half of the fixed-cost saving ticket 02 sets up: since every ticket is worked in a fresh session (confirmed in the grilling session), this removes a repeated full-repo discovery pass on every single ticket.

**Relevant files:**
- `~/.claude/skills/implement/SKILL.md` — currently a short, unstructured skill body with no explicit discovery/context-gathering step at all; this ticket adds one at the top, before the existing "Use /tdd where possible" line
- `~/.claude/skills/to-tickets/SKILL.md`'s `<local-ticket-template>`/`<issue-template>` (from ticket 02) — the exact field name/shape `implement` should look for

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] `implement`'s SKILL.md has an explicit first step: read the ticket's Relevant files field, open those files/sections directly
- [ ] Fallback behavior is explicit: missing field, stale/wrong hint, or hint that doesn't fully cover the work all fall back to normal search (CODEMAP.md / REFERENCE.md / Explore), not silent failure
- [ ] Skill still doesn't mandate a full CODEMAP.md or REFERENCE.md read as a default step — the whole point is avoiding that fixed cost when hints are present and correct
- [ ] No change to veins-of-london's local copy in this ticket — that's ticket 07 (propagation)
