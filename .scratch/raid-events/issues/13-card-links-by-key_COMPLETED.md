# 13 — Card links by key

**What to build:** An event choice or card can link to another card by that card's `key` as well as by its index, so big branching events don't break when cards are inserted or reordered. The rules for which links are legal stay the same: forward to any later card, or back to an earlier choice card. Number links keep working unchanged. Content lint reports a link to a key that doesn't exist, and so does the engine's runtime error. The storyboard tool reads and writes key links.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`_goto_target()` ~L319, `_next_index()` ~L337, card-level `goto` ~L305, choice resolution ~L426), `tests/test_events.gd`, `tests/test_event_content_lint.gd`, `tools/storyboard.html` (`OPTION_KEY_ORDER` ~L493, goto handling ~L584), `.claude/skills/implement-storyboard-event` (if it converts links), REFERENCE.md §3.9a Event choice checks, §3.9c Event label tokens and content lint.

**Status:** ready-for-agent

- [ ] Key links resolve to the same card an equivalent number would; the forward / earlier-choice-card rule still applies
- [ ] Unknown key: lint error, and a runtime error with no jump
- [ ] Tests: key forward link, key back-link to a choice card, illegal key back-link, unknown key; existing number-link tests pass unchanged
- [ ] Storyboard tool round-trips a key link
- [ ] REFERENCE.md documents key links
