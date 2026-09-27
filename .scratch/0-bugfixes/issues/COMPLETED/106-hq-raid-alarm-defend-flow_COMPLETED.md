# 106 — Wire HQ raids into alarm-gated defend flow

**What to build:** HQ raids currently always resolve automatically as a loss, with no player agency at all, even with the Alarm System upgrade installed — unlike vein raids, which (with the vein's alarm upgrade) queue a warning notification and let the player choose to travel/tap in and fight the raid off. Give HQ raids the same treatment: if the Alarm System upgrade is installed, a successful raid attempt against HQ queues instead of resolving immediately, pushes a notification with a Defend action (same pattern as the vein-raid notification), and tapping Defend starts the existing (currently unused) home-raid combat encounter and its win/loss debrief. Without the Alarm System installed, HQ raids behave exactly as they do today (automatic resolution, no notification). If the player doesn't act before the next daily tick, the raid resolves as a loss, same as an unclaimed vein defend expiring — this ticket does not yet add any guard-based chance to avoid that loss (see ticket 108).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] With the Alarm System upgrade installed, a successful HQ raid attempt queues rather than resolving immediately, and pushes a notification with a Defend action.
- [ ] Tapping Defend (from the notification, or an equivalent HQ-screen action) starts the existing home-raid combat encounter; winning and losing route into the existing win/loss debrief events.
- [ ] Without the Alarm System installed, HQ raids resolve exactly as they do today — no notification, no defend option.
- [ ] If the defend window is missed, the raid resolves as a loss at the next daily tick, same as before this ticket.
- [ ] Regression test covering: alarmed HQ raid queues and notifies, Defend triggers the home-raid combat, and an un-alarmed HQ raid still auto-resolves as before.
