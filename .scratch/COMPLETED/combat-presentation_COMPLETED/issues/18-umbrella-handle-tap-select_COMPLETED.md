# 18 — Umbrella-handle tap-select Dial widget + shorter stage

**What to build:** Human direction (2026-09-09), given live in conversation
rather than pre-specced:

1. Shrink the stage window (the animated-character "window") so it isn't as
   tall.
2. In the freed space at the bottom: left side shows the umbrella handle
   (the same prop `hq_dial.gd`'s loadout screen renders), right side shows 3
   blocks (Attack / Item / Run). Above the 3 blocks, a rectangle shows
   details of whichever Complication is currently selected.
3. Selecting a Complication: tap one of the 4 dots (screws) on the umbrella
   handle.
4. Casting: tap the button with 2 arrows on the umbrella handle.

Supersedes ticket 03/13's docked-right, full-height, rotate-to-select Dial
widget layout (see `docs/combat-animation-vision.md` §2.5's amendment note)
and folds in ticket 14's "Dial widget pixel-art pass" — this reuses real
umbrella art rather than commissioning new pixel art for the old vector
widget, and changes the interaction model too, which ticket 14's own scope
note explicitly excluded ("no functional/interaction change"). Ticket 14 is
marked `_COMPLETED` alongside this one — its actual intent (real art
replacing the placeholder) landed, just via a wider ticket than it specced.

**Blocked by:** None.

**Status:** `_COMPLETED`

- [x] `STAGE_HEIGHT` reduced (390×360 → 390×220) — `scenes/screens/
      combat.gd`.
- [x] `dial_widget.gd` rewritten: real `dial_device_base.png` + charge
      needle (same asset/measurement approach `hq_dial.gd` uses) replaces
      the vector clock/bezel `_draw()`; `handle_select(index)` (direct tap)
      replaces `handle_rotate(direction)` (relative rotate); `handle_trigger()`
      now fires only from a dedicated button hit-region (a drawn "⇄" glyph,
      since the source art has no such icon) instead of a short-swipe
      heuristic anywhere on the widget.
- [x] Widget now renders whenever the player has a seeded Dial at all (even
      with nothing loaded) rather than only once something is loaded —
      "always-shown furniture" per the human's framing.
- [x] `_build_command_deck()` reworked: Dial docks left (fixed box), a new
      `_build_complication_detail()` rectangle + the (now horizontal again)
      3-block action row dock right above/below each other, log unchanged
      below both.
- [x] `tests/test_dial_widget.gd` and `tests/test_combat_screen.gd` updated
      for the new API/layout — full suite green (2188 passed; 1 pre-existing,
      unrelated failure confirmed via `git stash` on the same run).
- [x] `docs/combat-animation-vision.md` §2.5 amended with a superseded note
      rather than silently rewritten.

- [x] `scripts/debug_combat_dial_screenshot.gd` added (windowed dev harness,
      same pattern as `debug_combat_fan_screenshot.gd`/
      `debug_hq_dial_screenshot.gd`) and run against a real GPU to check the
      geometry visually rather than leaving it eyeball-later. Caught and
      fixed two real bugs this way, neither visible from the headless test
      suite (no live render there):
      - `DOT_OFFSETS_NATIVE` originally used one shared radius for all 4
        screws (copied from `hq_dial.gd`'s own measurement); the render
        showed the left/right screws sitting noticeably closer to the clock
        face than top/bottom on this art, so the rings landed in the empty
        background beside the housing. Split into explicit per-dot offsets
        (top/bottom at 88 native px, left/right at 61) instead of one
        angle+radius pair.
      - The overlay (selection rings + the drawn two-arrow trigger icon) is
        on a separate `_overlay` Control specifically so it paints on top of
        the umbrella texture, not under it (same reason `StageSlot`'s own
        `_overlay` exists) — but every `draw_*` call inside `_draw_overlay()`
        needs the explicit `_overlay.draw_*(...)` prefix, not a bare call;
        a bare call draws onto `self`'s own canvas regardless of which
        node's `draw` signal invoked it, since the method still belongs to
        `self`. Missed this the first two passes (nothing painted at all,
        not even where the render had transparent background to paint over)
        before spotting that `StageSlot._draw_overlay()` already prefixes
        every call the same way. Screenshots re-confirmed clean after both
        fixes — see `.scratch/combat-presentation/dial-screenshots/`.
- [x] Also replaced the "⇄" text-glyph trigger icon with a drawn vector
      icon (two opposing arrow shafts+heads) after confirming the glyph
      wasn't rendering at all under `ThemeDB.fallback_font` — the exact font-
      coverage gap `scenes/components/symbol_glyph.gd` already exists to
      work around elsewhere in the project.

**Still open — narrower ART-REVIEW items a screenshot didn't settle:**

- `STAGE_HEIGHT`'s new value (220) is a judgment call, not fit against a
  specific screenshot — confirm on a real device that combatants still read
  clearly and the turn-order strip above isn't crowded.
- The 3-block action row's width budget (~200px, 3–4 EXPAND_FILL blocks)
  looked clean in the rendered screenshot at 1 dial + 3 blocks, but the 4th
  "Skip" block (mid-playback only) was never rendered in a screenshot —
  confirm no clipping/overflow there on-device.
- The Complication detail rectangle's copy ("Tap ⇄ to cast (1 charge)") is
  new prose, drafted against `CONTENT-GUIDE.md`'s tone bible. PROSE-REVIEW.
