# 02 — Pick a card image via directory picker

**What to build:** Each card in the desktop editor has an image control that opens a directory picker (File System Access API, as the editor already uses for events) to select the exact image under the project `assets/` tree, and stores it as the card's `image` field (`res://assets/...` path). The image can be cleared; existing images display.

**Blocked by:** 01 — Add and remove cards.

**Relevant files:** `tools/quest-editor.html` (`showDirectoryPicker` use ~lines 369-389), `tools/test_quest_editor.js`, `data/events/intro.json` (example `"image": "res://assets/events/intro/1.jpg"`), `assets/events/`. Path must map picked file → `res://assets/...` relative to the project root; ask if the picked root is ambiguous.

**Status:** ready-for-agent

- [ ] Choose an image from assets; preview shown; `image` path written correctly
- [ ] Remove image clears the field
- [ ] Tests for path mapping; human checks picker on Chrome/Edge
