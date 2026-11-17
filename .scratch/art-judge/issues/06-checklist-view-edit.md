# 06 — View and edit a checklist in the tool

**Status:** ready-for-agent

**What to build:** The Shots tab shows each shot's checklist, with item text, category and a hard flag. The user can edit item text, add or delete items, and toggle hard. Saving writes the checklist file and marks it `edited: true`.

An edited checklist is never silently rebuilt. If the brief changes after an edit:
- the tool shows a warning on the shot ("brief changed since you edited the checklist");
- the CLI refuses to rebuild that checklist without `--rebuild-checklist`, and says so.

Editing the checklist makes that shot's judgements stale.

**Blocked by:** 04 — Judgements in the Shots tab.

**Relevant files:**
- `tools/storyboard.html` (Shots tab shot card; ~3808 shot field editing + Save/Undo conventions)
- `tools/test_storyboard.js`
- `tools/storyboard_server.js` (`WRITE_DIRS` must cover the checklist location under `.scratch/`)
- `tools/art_judge/` (checklist rebuild rule, staleness)

- [ ] Checklist visible and editable per shot; Save writes it, Undo works like other shot fields.
- [ ] Saved edits set `edited: true`; the shot's judgements show stale.
- [ ] Brief change + edited checklist → tool warning; CLI refuses to rebuild without `--rebuild-checklist`.
- [ ] Brief change + unedited checklist → rebuilt automatically, as in 01.
- [ ] Tests: CLI refuse/rebuild behaviour; tool pure-section edit → stale, warning state.
