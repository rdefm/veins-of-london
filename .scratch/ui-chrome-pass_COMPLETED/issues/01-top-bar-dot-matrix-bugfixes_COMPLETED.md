# 01 — Top-bar dot-matrix bugfixes

**What to build:** Two bugs in the persistent top status board
(`scenes/components/top_bar.gd` + `scenes/components/dot_matrix_board.gd`),
both confirmed on-device via screenshot:

1. **Scramble freeze.** `DotMatrixBoard._begin_scramble()`'s "unchanged
   character" branch zeroes a cell's scramble timer (`scramble_line.append(0.0)`)
   without checking whether that cell is still mid-transition — if
   `set_lines()` is called again with the same target text while an earlier
   scramble on those cells hasn't finished (very likely on a day-tick,
   which fires several `EventBus.state_changed` events back-to-back per
   `systems/time_system.gd`'s tick pipeline), the cell's timer stops
   advancing while `_display_chars` is still holding whatever random
   scramble glyph it was mid-way through — that cell is now permanently
   stuck on garbage. Reproduced: two separate on-device screenshots taken
   minutes apart, after navigating between screens, showed the exact same
   garbled string, which is only possible if the board settled into a
   frozen bad state rather than still genuinely animating.
2. **Status text runs into/past the bag button.** `top_bar.gd`'s
   `_status_line_text()` output has no width cap and no reserved gap for
   the bag button occupying the board's right edge — `DotMatrixBoard.render()`
   draws characters left-to-right with no clip or truncation. On a long
   status string the trailing `£<cash>` can run off the visible screen
   edge entirely, and/or the button (drawn in the same amber-on-black as
   the board text) becomes visually camouflaged against character glyphs
   sitting right behind it. Reported symptom: "can't see the bag button
   (though tapping it still works)" + "doesn't show player £".

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] A scramble in progress always settles its cells to the correct target text, even if `set_lines()` is called again mid-transition with unchanged target text
- [ ] Status line text never overlaps the bag button's tap/visual area, and the full string (including `£<cash>`) is always visible on a 390-wide viewport at the current `STATUS_DOT_SIZE`
- [ ] Bag button remains visually distinguishable against the board background in all states
- [ ] Regression test added to `tests/test_dot_matrix_board.gd` (or equivalent) for the interrupted-scramble case
