# 03 — + New plate and Delete plate buttons

**What to build:** A **+ New plate** button in the Plates section, visible even when the board has no plates yet, adds an empty plate and focuses its name field. Each plate card has a **Delete plate** button with a confirm that says which shots will lose their plate. A newly added plate appears in every shot's Plate dropdown, so a manually created shot can be given one. Add and delete are single undo steps and are written on Save.

**Blocked by:** 01 — Plate model; 02 — Edit plates in the Plates section.

**Relevant files:**
- `tools/storyboard.html` (Plates section markup around `id="p-section"`, `renderPlates`, `renderShotTab`, `shotStructure`, `newShot`/`removeShot` as the pattern)
- `tools/test_storyboard.js`

**Status:** ready-for-agent

- [ ] + New plate shows on a board with zero plates and on a board created via "Create empty storyboard"
- [ ] New plate is selectable in a shot's Plate dropdown without reload
- [ ] Delete plate clears the plate on its shots; undo restores both
- [ ] Verified in a real browser end to end (create board, add plate, assign to a new shot, save, check `board.json`); any test board file removed afterwards
