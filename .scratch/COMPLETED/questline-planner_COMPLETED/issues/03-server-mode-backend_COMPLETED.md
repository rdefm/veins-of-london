# 03 — Server-mode backend in the page

**What to build:** when the storyboard page is served by the storyboard server, it uses a server-mode backend for the storage interface instead of the folder picker. On first visit the page saves the token from the URL in browser storage and removes it from the address bar. Every API call sends the token. Later visits without the token in the URL use the stored one. A refused token shows a clear message. When opened as a file, or served by anything else, the page keeps using the folder picker exactly as today. All tabs load and save through the server, including on a phone browser without File System Access, even though only the Quests tab is designed for phones.

The storyboard skills get a short note that server mode exists. Their workflows don't change.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `Main.dc.html` and `Laptop.dc.html` (header: tool name, server address / "server mode", save indicator). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 01 — Storage interface, folder-picker backend; 02 — Storyboard server.

**Relevant files:** `tools/storyboard.html` (startup at the end of the script: the `showDirectoryPicker` check, `loadHandle`/`reopen`, the folder-name and refresh header, focus reload), `tools/storyboard_server.js` (API contract), `.claude/skills/event-storyboard/`, `.claude/skills/implement-storyboard-event/`, `.claude/skills/plate-compositor/`, `CODEMAP.md` (storyboard row).

**Status:** ready-for-agent

- [ ] Human check: Header in server mode matches the mockup
- [ ] Backend picked at startup; folder picker unchanged when not served by the server
- [ ] Token captured once, stored, sent on every call, stripped from the URL
- [ ] Version-checked writes surface the server's conflict response through the interface
- [ ] Skills mention server mode
- [ ] Human check (laptop browser on the LAN URL, and phone): boards list loads, a proposal edit saves, a shot board saves, a plate upload works, a prose pack saves, focus reload picks up an on-disk change
