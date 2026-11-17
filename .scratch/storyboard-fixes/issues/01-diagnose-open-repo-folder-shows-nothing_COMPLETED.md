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

## Findings (diagnosis)

Repro: real Edge 157 (guest profile), real native `showDirectoryPicker` dialog driven via UI Automation, page driven over CDP.
- `file://`, fresh pick: loads (folder label set, boards + proposals + quests render, no console errors or rejections).
- `http://localhost:4317` (server running, no token -> picker fallback), fresh pick: loads.
- "Reopen <folder>" after reload (stored IDB handle): loads.
- NOT reproduced: total empty editor. Not tried: desktop Chrome, user's own profile/stale IDB handle.

Defect found with evidence: `#empty` ("No storyboards yet" card) has `display:grid`, which beat the `hidden` attribute, so with boards loaded the empty-state card still sat above the board (computed display `grid` while `hidden===true`; screenshot). Looks like "nothing loaded". Fix: global `[hidden]{display:none!important}`.
Hardening: `openRepo` now catches `loadAll`/`loadPlans` failures into the note. Regression tests added to `tools/test_storyboard.js` (the two textual checks; no DOM harness exists).

Human check: open `tools/storyboard.html` in Chrome (file://) and via `tools/storyboard_server.cmd` URL; pick the repo folder; no "No storyboards yet" card, boards in the dropdown. If still empty, press F12 and send the console + note text.

## ROOT CAUSE (confirmed)

Reproduced in real Chrome 157 by copying the user's `file://` IndexedDB (and localStorage state `vein-sb-tab=quests`) into a throwaway profile. At page load `showTab(rememberedTab())` (before `let plans` was declared) ran `renderQuests` -> `renderQuestBanner` -> `ReferenceError: Cannot access 'plans' before initialization`. The IIFE aborted before `$("open").addEventListener("click", openFolder)`, so every button was dead and no note appeared. Trigger: last-used tab was Quests (saved in localStorage). Fresh/guest profiles never hit it, hence the earlier non-repro.
Fix: restore the saved tab after all declarations (just before `detectServer()`). Regression test in `tools/test_storyboard.js`. Verified: same profile, no exception, click fires.
