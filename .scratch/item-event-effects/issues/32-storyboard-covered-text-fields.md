# 32 — Storyboard alert editor: covered/uncovered text fields

**What to build:** The storyboard tool's alert editor lets the author edit an option's `coveredText` and `uncoveredText` (showing the generic line as placeholder). The fields survive draft save, re-import and promote to live.

**Blocked by:** 28, 30

**Relevant files:** `tools/storyboard.html` and its draft-model node tests (the files ticket 28 touches).

**Status:** ready-for-agent

- [ ] Both fields editable on an option with an item-gated alert
- [ ] Round trip (save, import, promote) preserves them
- [ ] Draft-model test covers the round trip
