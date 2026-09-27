# 14 — "Crafting unlocked" notification fires and navigates to HQ before HQ is actually reachable

**What to build:** `data/events/james_meeting.json`'s `on_complete` sets `flags.craftingUnlocked = true`, fires the notification "Crafting unlocked. Try the workbench in HQ.", and navigates `currentScreen` to `"hq"`. But `scenes/screens/hq.gd` gates the entire HQ screen behind `flags.homeUnlocked`, showing only a "Locked" placeholder otherwise — and `homeUnlocked` isn't set until `home_raid_debrief_win`/`home_raid_debrief_loss` fire, which happens later in the intro sequence (after `home_raid_intro`). So on a fresh playthrough, the player is told crafting is ready and dropped straight onto a screen that says "HQ unlocks as you progress."

`homeUnlocked` staying gated behind surviving the home-raid event is deliberate (a "you earn your home base" beat) and is not being changed by this ticket.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `james_meeting`'s `on_complete` no longer fires the "Try the workbench in HQ" notification, and no longer auto-navigates to `"hq"`. `craftingUnlocked` is still set true here as before (it's read elsewhere independently of this navigation/notification).
- [ ] `home_raid_debrief_win.json` and `home_raid_debrief_loss.json`'s `on_complete` gain a new notification nudging the player toward HQ/crafting now that `homeUnlocked` is genuinely true (new prose — draft per `docs/CONTENT-GUIDE.md`'s tone bible, flag `PROSE-REVIEW`).
- [ ] Playing a fresh game through `james_meeting` no longer lands on a locked HQ screen.
- [ ] Playing through to `home_raid_debrief_win`/`_loss` shows the new nudge and HQ is genuinely accessible at that point.
- [ ] Existing event tests (`tests/test_events.gd`) updated for the removed navigation/notification assertion at `james_meeting`, with new coverage added for the debrief-stage notification.
