# 04 — Home raid quest dialogue plays only once

**What to build:** The home-raid quest (intro → combat → win/loss debrief) plays once. Every later home raid is a plain alarm: the player can go and defend or leave it. Defending starts combat with no intro or debrief dialogue. Winning means nothing is taken. Losing takes the same ore an undefended raid would. Either way the game carries on from the phone.

Cause (found during triage): `Home.trigger_defend()` (the alarm's defend) calls `Combat.start_home_raid_combat()`, which uses the quest's `home_raid` combat context. `_exit_home_raid` then always starts `home_raid_debrief_win/loss`. On a loss, `_after_home_raid_combat` also applies the quest's carried-ore halving instead of the normal raid loss.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/home.gd` (`trigger_defend`, `_apply_raid_loss`, `roll_daily_raid`, `_expire_pending_raid`)
- `systems/combat.gd` (`start_home_raid_combat`, `_exit_home_raid`, `_after_home_raid_combat`, context constants + exit dispatch)
- `systems/raid_alarms.gd`, `scenes/phone_apps/alarms_app.gd`
- `scenes/screens/hq.gd` (quest intro trigger via `homeRaidEventPending`/`homeRaidEventSeen`)
- `data/events/home_raid_intro.json`, `home_raid_debrief_win.json`, `home_raid_debrief_loss.json`
- REFERENCE.md §3.8 Home-raid event chain (document the separate alarm-defend context)
- `tests/test_home.gd`, combat tests

**Status:** ready-for-agent

- [ ] The alarm defend uses its own combat context, separate from the quest's `home_raid` context
- [ ] Alarm-defend win: no ore lost, no event started, player returned to the phone
- [ ] Alarm-defend loss: ore loss identical to an undefended raid (`_apply_raid_loss`), no event started, player returned to the phone
- [ ] The quest chain (intro, combat, debrief, carried-ore halving) is unchanged and still plays once
- [ ] Tests cover both alarm-defend outcomes and assert no debrief event starts
