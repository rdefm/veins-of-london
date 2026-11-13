# 01 — Storage interface, folder-picker backend

**What to build:** a prefactor with no behaviour change. All storyboard file access, in every tab, goes through one small path-based storage interface: read text, read JSON, write file, list directory and delete file. Each read returns a version token (a content hash), and a version-checked write refuses the save if the file's current version doesn't match the expected one. The existing folder-access helpers become the folder-picker backend behind this interface. Nothing outside the interface touches directory or file handles. Interface shape: spec § Storage interface and server mode.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (§ "folder access": `dirAt`, `readText`, `readJSON`, `writeFile`, `useRoot`, `idb`/`saveHandle`; every `dirAt(...)`/`getFileHandle`/`removeEntry`/`.entries()` call site, about 44 of them, including `loadAll`, `loadPlates`, `listDir`/`listSource`, board saves, proposal saves, promote, feedback.json, plate upload/delete, prose pack + `data/board.json` save), `tools/test_storyboard.js`, `CODEMAP.md` (storyboard row: mention the storage interface), `.scratch/questline-planner/spec.md`.

**Status:** ready-for-agent

- [ ] No call site outside the interface uses File System Access handles directly
- [ ] Reads return a version token; the version-checked write refuses a stale version (Node test over the pure hash/compare part, if it can be extracted)
- [ ] Existing storyboard tests still pass (`node tools/test_storyboard.js`)
- [ ] Human check (desktop Chrome/Edge): open folder, load boards, edit and save a proposal, save a shot board, upload and delete a plate, save a prose pack, promote: all behave exactly as before
