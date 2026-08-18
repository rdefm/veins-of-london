# 20 — Safe-area inset helper + event continue button unreachable

**What to build:** On a new game, the "Something woke you up" event (`data/events/home_raid_intro.json`) can't be advanced — the Continue button is unreachable. Root cause: no safe-area/gesture-inset handling exists anywhere in the project. `EventScreen`'s action bar (`scenes/screens/event.gd`, `_action_bar`) is anchored `PRESET_BOTTOM_WIDE` with `offset_bottom = -8`, pinning it directly under the OS gesture-nav bar on notched/gesture-nav devices, where it's untappable. Add a reusable safe-area inset helper and use it to lift the event action bar clear of the bottom inset.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A safe-area/inset helper exists (e.g. in `scenes/components/ui.gd`) that reads the OS bottom safe-area/gesture-inset and is reusable by other screens (ticket 21 will consume it too).
- [ ] `EventScreen`'s action bar bottom offset accounts for the safe-area inset instead of the hardcoded `-8`, so Continue/Rewind/choice buttons are always fully on-screen and tappable.
- [ ] Verified headless (syntax check) and manually noted for the human to confirm on-device on a notched/gesture-nav phone: new game → "Something woke you up" → Continue is tappable.
