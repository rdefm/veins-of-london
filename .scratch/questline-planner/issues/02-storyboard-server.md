# 02 — Storyboard server

**What to build:** a plain-Node, dependency-free local server that the author starts with one command or a double-click Windows launcher. It listens on the home LAN on a fixed port, serves the `tools/` folder and a small file API over the repo (read, list, write, delete), and prints a laptop URL, a LAN URL and a terminal QR code of the LAN URL. The QR encoder is hand-rolled because the server has no dependencies.

- A random access token is issued at start and carried in the printed URLs. API calls without it are refused.
- Reads cover the whole repo, and each returns the file's version (content hash).
- Writes and deletes are allowed only under `.scratch/`, `data/events/`, `data/quests/`, `assets/events/`, `assets/reference-plates/`, `data/board_prose/` and the file `data/board.json`. Anything else is refused, and so is path traversal out of the repo.
- A write with an expected version that doesn't match disk is refused with a conflict response. A matching version, or creating a new file, succeeds.

Whitelist decision (2026-11-13): the spec's four folders plus the three paths storyboard already writes (plates, prose packs, board.json), so every tab works in server mode (spec story 6).

**Blocked by:** None — can start immediately.

**Relevant files:** new `tools/storyboard_server.js`, new Windows launcher (e.g. `tools/storyboard_server.cmd`), new `tools/test_storyboard_server.js`, `CODEMAP.md` (rows for the server script and launcher), `.scratch/questline-planner/spec.md` (§ Storage interface and server mode, § Testing Decisions seam 2).

**Status:** ready-for-agent

- [ ] Node test starts the server on a random port and drives it over HTTP: serves the page, read/list/write work, a missing or wrong token is refused, a write outside the whitelist is refused, traversal is refused, a stale-version write is refused, a current-version write is accepted
- [ ] No npm dependencies; runs with plain `node`
- [ ] Startup prints laptop URL, LAN URL (both with the token) and a scannable QR
- [ ] Human check: double-click the launcher on Windows, scan the QR on the phone, and the page loads
