# 01 — Storyboard: live events open editable, and Save writes a new draft

**What to build:** In the storyboard tool's board picker, every live event is its own entry (e.g. "raid_shop.json — live") that always opens the live event itself, and every draft working copy is listed separately (e.g. "raid-shop-proposal.md — draft of raid_shop.json", one entry per draft). Opening a live entry imports the live file in memory only — nothing is written to the proposals folder on open. The live board is editable; edits stay in memory, and Save reads "Save as draft": it writes a new draft file (unique file name, carrying the live source and fingerprint as an import does today) and switches the picker to that draft. The live file is never written. Leaving a live board with unsaved edits asks to discard them, same as any board. Saving as draft when a draft of that event already exists creates another one alongside it (e.g. `raid-shop-proposal-2.md`); both are listed. Existing drafts open, edit and save exactly as now.

Out of scope: saving edits straight to the live file, a round-trip guard, pulling live changes into a draft.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (`liveEventOptions`, `workingCopyFor`, `openOrImport`, `importBoard`, `openLiveEvent`, `renderPicker`, the `board-select` change handler, `leaveBoard`, the Save handler and its title text, `checkDrift` / `drift` badge), `tools/test_storyboard.js` (live import / picker tests)

**Status:** ready-for-agent

- [ ] Picker lists each live event as its own "— live" entry, and each draft separately as "— draft of <file>"; a live event with a draft is no longer hidden behind it
- [ ] Opening a live entry writes nothing to disk
- [ ] A live board can be edited; Save is labelled "Save as draft" and writes a new draft file, then opens it; the live file is untouched
- [ ] Leaving a live board with unsaved edits prompts to discard
- [ ] A second "Save as draft" of the same live event creates a second, uniquely named draft; both show in the picker
- [ ] Existing draft boards behave as before (open, edit, save, drift badge)
- [ ] `node tools/test_storyboard.js` covers: picker entries (live + multiple drafts), no-write live open, save-as-draft creating a draft, a second draft of the same event; no new failures beyond the pre-existing ones
