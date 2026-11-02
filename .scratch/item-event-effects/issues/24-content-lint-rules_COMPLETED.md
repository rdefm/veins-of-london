# 24 — Content lint rules for tags, profiles and bypasses

**What to build:** The event content lint rejects: unknown tags; `entry`; unknown item ids in mods, requires, no-roll lists and `excludeItems`; malformed item profiles; `failRecovery` on a non-check option; Blast or Skeleton Key options carrying a check. It warns on: an authored alert raise alongside Blast; an item-gated option using `display: "hide"`. All live event data passes.

**Blocked by:** 22, 23

**Relevant files:** `tests/test_event_content_lint.gd`, `tools/lint_refs.json`, `data/events/*.json`, `data/recipes.json`; REFERENCE §3.9a.

**Status:** ready-for-agent

- [ ] Each reject and warn rule has a failing fixture test
- [ ] All live event data passes
