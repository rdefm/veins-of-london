# 02 — Edit plates in the Plates section

**What to build:** Each plate card in the Shots tab's Plates section becomes editable: name, camera, variant-of (dropdown of other plates), attach, prompt, notes. The Copy-prompt button stays. Every edit is one undo step and marks the board unsaved. Renaming a plate that already has an uploaded image shows a warning that the image file keeps its old name (the tool does not rename files).

**Blocked by:** 01 — Plate model.

**Relevant files:**
- `tools/storyboard.html` (`renderPlates`, `shotField`, `editShot`, `shotStructure`, `filesBlock`, `loadPlates`)
- `tools/test_storyboard.js`

**Status:** ready-for-agent

- [ ] Plate fields edit in place and persist through Save to the board's `board.json`
- [ ] Undo reverts a plate edit
- [ ] Rename warning shows only when an image for the old name exists
- [ ] Verified in a real browser (headless Chrome via the local storyboard server is fine): edit a plate field, undo, save
