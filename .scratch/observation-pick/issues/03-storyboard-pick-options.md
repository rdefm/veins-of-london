# 03 — Storyboard tool: author pick options

**Status:** ready-for-agent

**What to build:** The storyboard tool can author observation pick options (ticket 01's schema) without hand-editing JSON. In the option editor, an option can be switched to a pick: choose the observation (from the draft's observations), then per ore add one or more `{atLeast, outcome}` entries, where each outcome edits like a normal option outcome (result text, effects, goto, result image), plus the greyed-state reason. Play-through preview lets the author choose which ore to pick (or simulate "nothing qualifies"). The tool's lint mirrors the Godot lint rules from 01, and promote/import round-trips pick options byte-for-byte.

Already in place: the tool's Requires / check-mod / conditional-goto editors have an "Observation read" (`observed`) condition kind.

**Blocked by:** 01 — Observation pick: core mechanic (schema pinned in REFERENCE §3.9d).

**Relevant files:**
- `tools/storyboard.html` — option editor (`requiresBlock`, `OPTION_KEY_ORDER`, `outcomeSlots`, `setOptionMechanics`), observation editor (`renderObservation`, `observationUses`, `renameObservation` must also rename pick refs), `cardExits` (pick outcomes' gotos as graph edges), lint (`lintDraft`, `lintObservedRef`, `refs.maxOptions`), `condText`
- `tools/test_storyboard.js` — tests; note one failure already there unrelated to this ticket ("import → promote reproduces every live event byte-for-byte" on `stockpile_raid*.json`)
- `tools/promote_storyboard.js`, `tools/lint_refs.json`
- `.claude/skills/implement-storyboard-event/` if its promote steps need to know about picks
- `docs/REFERENCE.md` §3.9d Observation

- [ ] An option can be made a pick and edited per ore/tier in the tool
- [ ] Renaming/deleting an observation updates/warns about pick refs
- [ ] Pick outcomes' gotos show in the graph and route play-through
- [ ] Tool lint flags bad pick refs the same way the Godot lint does
- [ ] Import → promote round-trips a pick option unchanged
- [ ] `node tools/test_storyboard.js` passes (apart from the stockpile_raid failure already there, unless fixed)
