# 08 — Quest events

**What to build:** the events section of the quest sheet.

- **Entries.** A quest lists several event entries. Each shows its state: `live` if the file exists in `data/events/`, `draft` if a storyboard draft exists, `planned` otherwise. State is computed on load and never trusted from the file. An entry whose live event or draft no longer exists is flagged as stale.
- **Adding.** The author adds a planned event by name or id before it exists, or picks a live event or storyboard draft from a list.
- **Managing.** Entries can be reordered and removed.
- **Opening.** Tapping an entry opens that event or draft in the storyboard.
- **Create draft.** A planned entry has "Create draft". It runs the storyboard's new-board flow with the entry's id as the board id and its title, and the entry becomes a draft.

The file format keeps the later-use "fires on start" flag, with no UI. State resolution works from provided lists of live ids and draft ids.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `QuestSheet.dc.html` (Events section: drag handle, title over id, state chip, Create draft on planned, remove ✕, "Pick event or draft…" and "+ Planned"). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 06 — Quest sheet: fields, statuses, mechanics state, undo.

**Relevant files:** `tools/storyboard.html` (planning-model section; `LIVE_EVENTS_DIR`, `PROPOSALS_DIR`, `blankBoard`, `openOrImport`, `liveEventOptions`, the new-board flow behind `#new-board`), `tools/test_storyboard.js`, `data/events/`, `.scratch/writing-revamp/`, `.scratch/questline-planner/spec.md` (§ Events).

**Status:** ready-for-agent

- [ ] Human check: Events section matches the mockup
- [ ] Node tests: add, reorder and remove entries; state resolution for live, draft, planned and stale
- [ ] Create draft makes a board with the planned id and title, and the entry then resolves as draft
- [ ] Human check: pick a live event, add a planned one, Create draft and land in the new board, tap an entry to open it
