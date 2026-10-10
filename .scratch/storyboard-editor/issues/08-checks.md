# 08 — Checks

**What to build:** Each option has a free-text **check intent** note (`checkNote`) always available, plus optional real mechanics: base, attempts, mods, requires, effects, perSuccess, bySuccesses. Reuse quest-editor's shared Choice mechanics UI/logic where it helps; quest-editor stays a separate tool.

**Blocked by:** 07 — Player options + outcome routing.

**Relevant files:** `tools/quest-editor.html` (`Choice mechanics (shared)` markers), `tools/quest-editor-mobile.html`, `tools/test_quest_editor.js`, `tools/storyboard.html`, REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] `checkNote` editable on any option, shown in editor and on the graph node
- [ ] Mechanics fields editable; turning a check on swaps `result_text` for success/fail (never both)
- [ ] bySuccesses outcomes appear per success count and are routable (07)
- [ ] Shared code reused rather than copied where practical; quest-editor tests still pass
