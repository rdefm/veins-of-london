# 13 — Dial widget doesn't render in combat despite a loaded Complication

**What to build:** `scenes/screens/combat.gd`'s `_build_command_deck()` only
adds the `DialWidget` when `player["dial"] != null and not
dial["loadedComplications"].is_empty()` — confirmed on a real save with an
owned Dial and a loaded Complication that the widget still doesn't appear in a
fight. This is not the documented, correct "no Dial yet" empty case (covered
by existing tests: `dial_widget_does_not_render_when_the_player_has_no_dial` /
`...loadedComplications_is_empty`) — diagnose the actual break in the chain
between a genuinely-loaded Dial and the widget appearing on-screen (candidates
worth checking first: whether the specific combat context reached in the
report reaches `_build_command_deck()` at all, whether `player["dial"]` at
render time is stale/desynced from what was actually loaded, or whether
`loadedComplications` is empty for a reason not visible from the HQ/Bag
management UI). Root cause not yet known — this is a diagnosis ticket, not a
guessed fix.

**Blocked by:** None — can start immediately.

**Status:** done

**Root cause (not any of the three candidates above — all three were built
and ruled out via headless repros of the real Dial.load_complication() ->
Combat.start_mugging() -> CombatScreen flow, including through a save
export/import round trip):** this was never a data/state bug. The widget was
always being built correctly, with correct data, and added to the tree —
`_build_command_deck()`'s HBoxContainer (action-card row + log on the left,
DialWidget docked right at a fixed width) has a combined minimum width that
regularly exceeds a real phone viewport's available content width (measured:
~375px needed vs. ~358px available on this project's 390px-wide viewport —
mostly from the 3-card action row, not the Dial itself). Because the
project's screen-wide outer ScrollContainer (`UI.scroll_container()`, used by
every screen via `UI.screen_body()`) has horizontal scrolling disabled
project-wide, that overflow was silently clipped past the true right edge of
the device screen with no way to scroll to it. This is exactly why the
existing `dial_widget_renders_docked_beside_the_action_deck_when_something_
is_loaded` test (and every other case in that file) never caught it: none of
them are added to a real, sized SceneTree, so Control layout
(`global_position`/`size`) never resolves — they only prove the node exists.

**Fix:** `_build_command_deck()` now wraps the deck in its own new
horizontal-only `TouchScrollContainer` (existing project class), so an
overflowing row stays reachable via a horizontal swipe instead of being
clipped unreachably, and — as a side effect of how `ScrollContainer` reports
its own minimum size — the deck's oversized width also stops inflating the
*outer* screen-wide scroll region past the device's actual width.

- [x] Reproduced: headless repro of the real load-complication ->
      start-combat flow inside a real, sized (390x844, matching
      project.godot's viewport) SceneTree confirmed the widget was present
      in the tree but rendered with its right edge past the visible screen.
- [x] Root cause identified and fixed at the source (see above) — not a
      guessed fix; the three candidate hypotheses in the original ticket
      text were all built and ruled out first.
- [x] Regression test added:
      `dial_widget_is_scrollable_into_view_when_the_command_deck_overflows_
      a_phone_viewport` in tests/test_combat_screen.gd. Unlike every other
      case in that file, it builds a real CombatScreen inside a real, sized
      SceneTree, lets layout settle across real awaited frames, asserts the
      scenario genuinely overflows the viewport at rest (so the test can't
      pass vacuously), then asserts the widget can be scrolled fully into
      view. Confirmed to fail against the pre-fix code (temporarily
      reverted combat.gd, reran — 1 failure, this case) and pass with the
      fix; full suite (2079 cases) passes.
- [x] Headless-verifiable only — no on-device confirmation was possible in
      this environment. **PROSE-REVIEW: none (no new user-facing prose).**
      Flagging for the human: please confirm on a real phone-width device
      that (a) the Dial widget is visible/usable in a fight with a loaded
      Complication, and (b) if the action-card row is wide enough to clip
      it, a horizontal swipe on the command deck reveals it — the swipe-to-
      reveal UX itself wasn't specified by the ticket and is a reasonable
      but not the only fix shape (shrinking the action cards or the Dial's
      fixed width instead was the alternative); flag if the swipe feels
      wrong and a narrower/resized layout is preferred instead.
