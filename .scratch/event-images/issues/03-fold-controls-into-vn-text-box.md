# 03 — Fold Continue/Rewind/choice controls into the VN text box

**What to build:** ticket 02 ships VN-mode's full-portrait image and
single-card text box, but still drives Continue/Rewind/choice through
today's separate bottom `HBoxContainer` action bar underneath it. This
ticket retires that separate bar for VN-mode events only and moves those
controls into/onto the text box itself, matching the approved mockup:
Continue becomes a forward-arrow glyph in the box's bottom-right corner;
Rewind (when `Events.can_rewind()`) and choice buttons (when
`Events.is_awaiting_choice()`) attach to/within the same box rather than a
separate bar. Non-VN-mode events keep today's bottom action bar exactly as
it is.

**Blocked by:** 02 — VN-mode full-portrait single-card event layout

- [ ] VN-mode events render no separate bottom action bar; the box itself
      carries whatever controls the current card needs
- [ ] Continue (the non-choice, non-final-card case) renders as an
      arrow-style control inside the box, in the bottom-right corner as
      mocked up, and still calls `Events.advance()`
- [ ] When `Events.can_rewind()` is true, a Rewind control is attached to/
      within the box (not the old action bar) and still calls
      `Events.rewind()`
- [ ] When `Events.is_awaiting_choice()` is true, the current card's choice
      buttons render attached to/within the box (not the old
      `HBoxContainer`) and still call `Events.choose(i)` with the correct
      index
- [ ] The box's per-card-type accent (from ticket 02) is unaffected by the
      added controls — border/fill styling still reads correctly with a
      control docked in the corner
- [ ] Non-VN-mode events' existing bottom action bar (Continue/Rewind/
      choice `HBoxContainer` and its `_style_action_button` styling) is
      completely untouched
- [ ] `tests/test_event_screen.gd` covers: a VN-mode event on a choice card
      renders its choices attached to the box and no separate action bar;
      a VN-mode event with Rewind available renders it attached to the box;
      a non-VN-mode event's action bar is unaffected
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean on every
      touched `.gd` file; `scripts/run_tests.sh` passes
