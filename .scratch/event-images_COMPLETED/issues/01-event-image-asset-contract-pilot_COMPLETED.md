# 01 — Event image asset contract + pilot wire-in

**What to build:** the event-card image slot (`scenes/screens/event.gd`,
`systems/events.gd`) already renders whatever `image` path a revealed card
sets — that mechanism shipped complete under ui-chrome-pass ticket 11
(`.scratch/ui-chrome-pass_COMPLETED/issues/11-events-ui-implementation_COMPLETED.md`).
No event currently sets one, and no `assets/events/` art exists yet. This
ticket fixes the asset contract those images will load through — mirroring
`docs/adr/0003-app-icon-asset-contract.md`'s shape for app icons — and
proves it end-to-end by wiring one real scripted event with actual art
Richard supplies.

**Blocked by:** None — can start immediately

- [ ] New ADR (`docs/adr/NNNN-event-image-asset-contract.md`) records: the
      path convention (`res://assets/events/<event_id>/<n>.png`, already
      named in `docs/ui-vision.md` §11 — this ADR is what makes it a durable
      decision record, not a restatement), format (PNG with alpha),
      per-image size/import settings, and the `<n>` numbering rule for an
      event that swaps its image mid-event (e.g. `1.png` = the image set by
      the first card that specifies one, `2.png` = the next card that sets a
      different one, in authoring order — not tied to card index)
- [ ] Thumbnail canvas size locked as a new row in `docs/ART-BIBLE.md` §3's
      size table (§11's indicative 160–180px tall / 358px wide range —
      pick one exact value and record it there, the same table combatant/
      backdrop/effect sizes already live in)
- [ ] Missing-art behaviour confirmed unchanged: an `image` key pointing at
      a file that doesn't exist yet still collapses the slot to zero height
      silently (per `_refresh_image_slot()`'s existing `ResourceLoader.exists()`
      check) — no placeholder box, no code change needed for this
- [ ] One real scripted event (e.g. `intro.json` or `col_a1_intro.json` —
      implementer's/Richard's pick, any event with a natural beat change
      works) gets `image` keys wired on at least two of its cards: one
      setting an initial image, a later one swapping it to a different
      image — proving both the static-image path and the sticky-until-
      next-entry swap, not just one image per event
- [ ] Art for the pilot event is supplied by Richard per the ADR's
      format/size — this checklist item may stay open until that hand-off
      happens; the ADR and canvas-size decisions above don't depend on it
- [ ] Verified on-device or via screenshot: the pilot event's image slot
      shows the first image, then swaps to the second at the right card,
      and Rewind past the swap point reverts the displayed image too
      (already covered by the existing derived-state mechanism, not new
      code — this checks it, doesn't build it)
- [ ] After this lands, any other event's art is a JSON `image` key + PNG
      drop under its own `assets/events/<event_id>/` folder — no ticket
      required, same as `docs/adr/0003-app-icon-asset-contract.md`'s icon
      rollout
