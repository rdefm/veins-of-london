# 10 — Quest editors support checks, gating, branches and timing

**What to build:** The desktop and mobile quest editors can author option `id`, `check` (all modifier types, min/max, show, attempts), `success`/`fail` outcomes, `requires` (display + reason), `goto`, and event `at`, round-tripping JSON without loss.

**Blocked by:** 02, 03, 04, 05, 06.

**Relevant files:** `tools/quest-editor.html`, `tools/quest-editor-mobile.html`, `tools/test_quest_editor.js`, `docs/agents/quest-drafts.md` (draft format, if fields flow through drafts), REFERENCE.md check-schema section, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Every new field editable in both editors.
- [ ] Round-trip test: event with all new fields loads and saves to identical JSON.
- [ ] Legacy events open and save unchanged.
- [ ] Human checks (desktop + phone) listed in report.
