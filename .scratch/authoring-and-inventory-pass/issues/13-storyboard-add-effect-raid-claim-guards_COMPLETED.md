# 13 — Storyboard add-effect control: raid, claim, guards

**What to build:** Authors get an "Add effect" dropdown on plain options, on success and fail outcomes, and on any other per-outcome effects list the tool edits. This ticket adds Raid vein (with depth), Claim vein and Adjust guards, with add, edit and remove. Other effects stay read-only and pass through untouched. New controls sit outside the section shared with the mobile quest editor, which must stay byte-identical. The mobile editor passes the new fields through.

**Blocked by:** 09, 10

**Relevant files:** `tools/storyboard.html`, `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `tools/test_quest_editor.js`, `tools/quest-editor-mobile.html`

**Status:** ready-for-agent

- [ ] Raid, claim and guard effects can be added, edited and removed on options and outcomes
- [ ] Fields survive save, reload and promotion
- [ ] Unknown effects stay read-only and unchanged
- [ ] `tools/test_quest_editor.js` is green with the shared section unchanged
- [ ] The mobile editor keeps the new fields intact
- [ ] Human QA block lists the dropdown flow
