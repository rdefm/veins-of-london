# 01 — Diagnose: picking the repo folder in the storyboard tool opens nothing

**Status:** ready-for-agent

**What to build:** A root-caused diagnosis (and then the fix) for this report: in the storyboard tool, the "Open repo folder" button is present and clickable; choosing the veins-of-london folder in the picker does not load anything into the editor (no boards, no proposals, no quests). Diagnose by reproducing with the real File System Access picker in a real Chrome/Edge window, not by reading code or stubbing handles. A previous session guessed (server-mode token fallback) and did not fix it; do not repeat that guess without evidence.

Method (use the diagnosing-bugs skill): build a repro loop first. Capture the exact state after the pick: any note text under the toolbar, console errors and unhandled rejections, whether `useRoot`/`openRepo`/`loadAll`/`loadPlans` run, and what `isRepoRoot`, `list` and `readText` return on the real handle. Compare against what works (server mode over the same repo loads 97 questline nodes headless). Candidates to confirm or rule out, not assume: swallowed exception in `openRepo`/`loadAll`/`loadPlans`; `isRepoRoot` false-negative on a real handle; browser blocking the folder (system-file rule, e.g. the `.exe` in the repo root); `showDirectoryPicker` opened from `file://` vs `localhost`; stale IndexedDB handle / "Reopen" path; the page being served in server mode so the picker is bypassed; a rendering path that runs but shows an empty state.

Deliver: the root cause stated with evidence, the fix, a regression test where the logic is testable in `tools/test_storyboard.js`, and a short on-device check for the human (which browser, which URL, what they should see).

**Blocked by:** None — can start immediately.

**Relevant files:**
- `tools/storyboard.html` — `openFolder`, `useRoot`, `openRepo`, `detectServer`, `useServer`, `startFolderMode`, `folderBackend` (`isRepoRoot`, `list`), `loadAll`, `loadPlans`, `setNote`
- `tools/storyboard_server.js`, `tools/storyboard_server.cmd` — server mode and token
- `tools/test_storyboard.js`
- Skill: `diagnosing-bugs`

- [ ] Reproduced with a real folder pick in a real browser; repro steps recorded in the ticket
- [ ] Root cause identified with evidence (log/console output), not inferred
- [ ] Fix makes picking the repo folder load boards/proposals/quests in both `file://` and `localhost` use
- [ ] Failure to open always surfaces a visible note explaining why (no silent empty editor)
- [ ] Regression test added where testable; `node tools/test_storyboard.js` passes for the touched area
- [ ] Human on-device check listed
