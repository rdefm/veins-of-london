# 13 — Engine routing extension

**What to build:** The events engine gains, staying forward-only: **card-level `goto`** on plain cards; **conditional `goto`** — ordered `[{if, card}, …, {card}]` evaluated with `condition_met`; **`end: true`** finishing the event at that card. Visited-card path, images and Rewind keep working.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`_goto_target` ~263, next-card ~274, played cards ~280, `condition_met` ~452), `tests/test_events*.gd`, `tests/test_event_content_lint.gd`, REFERENCE.md §3.9a Event choice checks (Goto, Lint bullets), §3.9 Snapshots & Rewind.

**Status:** ready-for-agent

- [ ] Card `goto` jumps on Continue; backwards/invalid rejected like outcome gotos
- [ ] Conditional list picks first matching entry; last without `if` = else
- [ ] `end: true` finishes the event at that card
- [ ] `revealed_cards()` / `current_image_path()` / Rewind correct across all three
- [ ] Content lint validates the new keys
- [ ] REFERENCE.md §3.9a updated; tests + check_all clean
