# 15 — Claude skill: implement a storyboard event

**What to build:** A skill the user points at a draft built in the storyboard tool ("implement/promote X"). It actions open "for Claude" comments (resolving them), converts branches → flat event (topological order, start branch first, every jump forward, `{branch, card}` → card indexes, conditional `then` → conditional `goto`, keys/notes/comments stripped), writes `data/events/<id>.json`, runs tests, reports. Conversion is a node script sharing the tool's model section.

**Blocked by:** 08 — Checks; 09 — Comments; 13 — Engine routing extension.

**Relevant files:** new `.claude/skills/<name>/SKILL.md`, new promote script under `tools/`, `tools/storyboard.html` (model section), `tools/test_storyboard.js`, `data/events/*.json`, `tests/test_event_content_lint.gd`, `scripts/run_tests.sh`, REFERENCE.md §3.9a Event choice checks, `docs/CONTENT-GUIDE.md`.

**Status:** ready-for-agent

- [ ] Promote script node-tested: forward-only output, index mapping, stripping, import(promote(d)) matches d's routing
- [ ] Skill actions and resolves open for-Claude comments; flags PROSE-REVIEW
- [ ] Written event passes content lint + full suite
- [ ] CODEMAP updated
