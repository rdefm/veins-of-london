# 09 — ToDo: collapsible questline sections

**What to build:** ToDo groups objectives into clear collapsible sections per questline: Tutorial, Collective, and Business Empire (placeholder with an empty state until that questline exists). Active questlines start expanded; completed ones start collapsed and marked done. Collapse state is session-only (UI state, not saved, not in the state tree). The Collective ledger stays under Collective. Headers/rows restyled for clarity in line with phone app styling.

**Blocked by:** 08 — Rename Notes app to ToDo.

**Relevant files:** `systems/todo.gd`, `scenes/phone_apps/todo_app.gd` (after 08), `data/objectives.json`, `systems/objectives.gd`, `scenes/components/ui.gd`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Sections: Tutorial, Collective, Business Empire placeholder
- [ ] Tapping a header collapses/expands; state survives closing/reopening the app in-session, resets on restart
- [ ] Defaults: active expanded, completed collapsed + ticked
- [ ] Questline grouping comes from the system; screen only renders
- [ ] PROSE-REVIEW flag on any new strings
