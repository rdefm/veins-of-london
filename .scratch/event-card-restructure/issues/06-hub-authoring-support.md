# 06 — Authoring support for hubs

**What to build:** Writers can build conversation hubs without hand-editing JSON. In the storyboard tool and both quest editors, an option on a hub choice card gets an "advance option" toggle (the hub's exit, shown as →), and the hub card gets its advance-rule field (anytime / all asked / after N). Storyboard play-through shows the exit as → and honours the advance rule. Promote carries both fields into the live event and refuses a hub with no exit option. The storyboard preview layout is otherwise unchanged.

**Blocked by:** 05 — Conversation hubs: separate advance button.

**Relevant files:** `tools/storyboard.html`, `tools/quest-editor.html`, `tools/quest-editor-mobile.html` (shared "Choice mechanics" section stays byte-identical across all three), `tools/promote_storyboard.js`, `tools/test_quest_editor.js`, `.claude/skills/implement-storyboard-event/SKILL.md`, `docs/writing-guide.md` "Hub loops", `docs/REFERENCE.md` §3.9a, `CODEMAP.md` (tools rows).

**Status:** ready-for-agent

- [ ] Advance-option toggle and advance-rule field in all three tools
- [ ] Storyboard play-through renders the exit as → and gates it by the rule
- [ ] Promote writes both fields; refuses a hub with no exit option
- [ ] `test_quest_editor.js` covers the new fields and the byte-identical Choice mechanics section
- [ ] implement-storyboard-event skill doc mentions the exit flag and advance rule
