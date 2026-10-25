# 05 — Content lint in the storyboard tool

**What to build:** The storyboard tool shows content-lint problems (unknown flag/item/contact/path/recipe rung, label time words vs `at`, bad gotos, bad `choice` refs, too many options, etc.) live while editing, and Promote's confirm repeats them as a warning — it never blocks. A headless Godot export script writes the lint's reference lists (flags, items, contacts, state paths, recipe rungs, event ids with their choice-card keys and option ids) to a refs file the tool reads. The GDScript lint stays the authority; a test fails when the refs file is stale or when the tool's lint and the GDScript lint disagree on the shipped events.

**Blocked by:** 03 — Choice refs and choice memory by card key.

**Relevant files:** `tests/test_event_content_lint.gd` (rules + `_known_refs`), `tools/storyboard.html` ("Draft model (pure)" section, edit bar, `promoteBoard`), `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `scripts/check_runner.gd` (headless boot pattern), new export script under `tools/` or `scripts/`, `CODEMAP.md`, REFERENCE.md §3.9a, §3.9c.

**Status:** ready-for-agent

- [ ] Export script writes the refs file headless; documented how to regenerate
- [ ] Tool lints the open draft on edit and shows violations in the edit bar
- [ ] Promote confirm lists violations as warnings; Promote still proceeds on confirm
- [ ] Parity test: JS lint and GDScript lint give the same violations on every shipped event; stale refs file fails a test
- [ ] CODEMAP updated
- [ ] Full suite + `scripts/check_all.sh` + `node tools/test_storyboard.js` green
