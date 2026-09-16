# 02 — VN-mode full-portrait single-card event layout

**What to build:** today's persistent image slot (ticket 01) is a small
358×170 strip pinned above a `ScrollContainer` that accumulates every
revealed card (`scenes/screens/event.gd`'s `_cards_box`). This ticket adds
a second layout mode — "VN mode" — for events that use art heavily: a
full-bleed portrait image filling the screen between the `TopBar` and the
bottom action bar, with exactly one card's speaker/text shown at a time in
an overlay text box, replaced on each advance rather than accumulated.

Whether an event uses VN mode is decided **once, for the whole event**, not
per card: an event is VN-mode if *any* card anywhere in its `cards` array
carries a non-null `image` key (i.e. `Events.current_image_path()` would
ever return non-null across the event's full run); otherwise the event
keeps today's small-slot + scrolling-stack layout completely unchanged,
including for any of its individual cards that happen to omit `image`.

Continue/Rewind/choice controls stay on today's separate bottom action bar
for this ticket — folding them into the text box itself is ticket 03. This
ticket's bar is met once VN-mode events show one full-portrait image with
one text box per card, correctly advancing, with the existing bottom
action bar still driving that advance underneath it.

**Blocked by:** None — can start immediately

- [ ] VN-mode detection lands as a small pure function (`systems/events.gd`
      is the natural home, alongside `current_image_path()`) — true iff any
      card in the event definition's `cards` array specifies a non-null
      `image` key, computed from the static event definition, not just
      revealed-so-far cards, since the mode must not flip mid-event
- [ ] `EventScreen` branches on that detection: VN-mode events render the
      new full-portrait frame + single overlay text box; non-VN-mode events
      render exactly the current `_image_frame` (170px slot) +
      `_cards_box` (scrolling stack) path, unchanged
- [ ] VN-mode's image frame fills the full width and the full height between
      `UI.top_bar_clearance()` and the bottom action bar's top edge, using
      `STRETCH_KEEP_ASPECT_COVERED` as today
- [ ] VN-mode shows exactly one card's content (label/speaker/text) at a
      time — advancing (`Events.advance()` / `Events.choose()`) replaces the
      box's content; no prior card's text remains visible or scrollable
- [ ] VN-mode's text box border/fill accent follows the current card's
      `type` the same way `_style_card()` does today: `tension` →
      `MapStyle.DANGER_COLOUR` border, `craft` → `calc_gold`/`calc_gold_light`
      border+fill, everything else neutral
- [ ] New display-canvas size for the VN-mode portrait frame is recorded as
      an amendment to `docs/adr/0005-event-image-asset-contract.md` (the
      existing 358×170 entry was sized for the old landscape slot and does
      not apply here) — pick one exact pixel size and note it also needs a
      row in `docs/ART-BIBLE.md` §3 alongside the existing "Event
      thumbnail" row
- [ ] No source-art changes required to ship this: existing
      `assets/events/intro/*.png` files render cropped-to-cover at the new
      larger size via `STRETCH_KEEP_ASPECT_COVERED`, same as the ADR already
      allows for the old slot
- [ ] `tests/test_event_screen.gd` covers: VN-mode detection true for an
      event with an image on any card (including one buried deep in the
      array, to prove it's not just checking the first card), false for an
      event with none; single-card replacement (advancing leaves exactly
      one card's content in the tree, not two); a non-VN event's layout is
      byte-for-byte unaffected; per-card-type accent applied on the box
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean on every
      touched `.gd` file; `scripts/run_tests.sh` passes
