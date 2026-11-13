# 06 — Quest sheet: fields, statuses, mechanics state, undo

**What to build:** tapping a map node opens the quest sheet, and the map stays in place behind it. It's a bottom sheet at phone width (close by swiping down or tapping ✕) and a side panel on wide screens.

Sheet order: title + id, summary, events (placeholder, filled in by 08), flow (read-only follows / followed-by with choice labels; actions come in 07), mechanics state, statuses, notes.

- **Fields.** Title, a one-to-three-line summary and notes are editable. The id is made from the title and stays editable until the quest has mechanics or a draft/live event, then it's fixed. Ids are unique across all questlines.
- **Mechanics state.** Shown read-only. Hard-coded quests also show their linked objective id, and hard-coded mechanics are never editable here.
- **Statuses.** One per configured category. Tap to cycle, long-press to pick a value.
- **Undo.** Every planning edit can be undone within the session.

**Mockup:** https://claude.ai/artifact/2iHxNhNundq3VL5EiGMmvv, saved copy in `.scratch/questline-planner/mockup/` (see its README). Artboards: `QuestSheet.dc.html` (section order, title/id lock, mechanics box, 2×2 status tiles, notes), `PhoneSheet.dc.html` (bottom sheet), `Laptop.dc.html` (400px side panel), `States.dc.html` (status picker). Build to match the mockup's layout, labels, controls and styling. Its quest content is sample data.

**Blocked by:** 05 — Read-only questline map.

**Relevant files:** `tools/storyboard.html` (planning-model section: rename/re-id with the fixed-id rule, set/cycle status; `makeHistory` for undo snapshots; the Undo button and Ctrl+Z handling), `tools/test_storyboard.js`, `.scratch/questline-planner/spec.md` (§ The quest sheet, § Statuses).

**Status:** ready-for-agent

- [ ] Human check: Sheet, bottom sheet, side panel and status picker match the mockup
- [ ] Node tests: re-id allowed only before mechanics or draft/live events, rejected on a duplicate id across questlines; status set and cycle
- [ ] Undo restores the previous planning snapshot and autosaves
- [ ] Human check (phone): sheet opens and closes by swipe and by ✕, long-press picker works, targets are thumb-sized. Laptop: side panel shows the map alongside
