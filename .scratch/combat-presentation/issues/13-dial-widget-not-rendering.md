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

**Status:** ready-for-agent

- [ ] Reproduced: a save with an owned Dial and at least one loaded
      Complication enters a fight and the widget does not appear.
- [ ] Root cause identified and fixed at the source, not papered over.
- [ ] Regression test added covering the specific condition that was broken
      (not just the two existing "correctly empty" cases).
- [ ] Confirmed on-device (or noted if only headless-verifiable) that the
      widget now appears and is usable in a real fight.
