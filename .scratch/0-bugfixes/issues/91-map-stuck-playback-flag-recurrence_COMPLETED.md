# 91 — Map: stuck playback flag recurrence (taps dead / vein doesn't connect until tab switch)

**What to build:** Two symptoms, both reported again on a build that already includes #81's fix (2026-08-26, "clear map playback guard on every navigation-away-from-map, not just tab teardown"): (1) seeding a vein sometimes doesn't show its line connecting until the player leaves the Map tab and returns; (2) after interacting with the Map tab a while, tapping a district/vein sometimes does nothing until leaving and returning. #81 diagnosed both as the same root cause — `systems/map_events.gd`'s `playing` flag leaking `true` when a queued animation is interrupted by a path other than tab teardown — and shipped a fix. Since it's recurring, either #81's fix doesn't cover the actual interruption path being hit, or a new interruption path was introduced since.

**Where:** `systems/map_events.gd` (`is_playing()`, `begin_playback()`, `advance()`, `abandon_playback()`), `scenes/components/map_canvas.gd` (`_exit_tree()`, `_handle_tap()`, `_maybe_start_playback()`, and wherever #81 added its new navigation-away hook).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Re-verify #81's fix (clearing the playback guard on every navigation-away-from-map) is actually present and wired correctly on current code.
- [ ] Find the interruption path currently leaking `playing` stuck `true` — #81's original prime suspect was a district-deck event firing mid-animation; check that and any other path that can stop a `_play_queue()` coroutine without going through the hook #81 added.
- [ ] Fix so `abandon_playback()` (or equivalent) is called from every such interruption path.
- [ ] Add a regression test that starts a queued animation, interrupts it via the specific path found, and confirms `is_playing()` recovers to `false` and a subsequent tap/seed-join behaves normally — the existing suite evidently doesn't cover this path since it shipped broken again.
- [ ] Manual check noted for the human: seed several veins back-to-back and interact heavily with the map (tapping districts, triggering district-deck events) for a few minutes, confirming taps stay responsive and new veins connect without needing a tab switch.
