# 43 — Verify/polish raid-defend-on-alarm flow

**What to build:** The human reported being raided with no option to defend, despite having alarms installed — but the mechanic already exists in code: with the `alarm` upgrade purchased (`Cultivating.add_alarm()`, `cultivating.gd:536`, `data/vein_alarm.json`), a successful raid attempt queues via `Raiding._queue_defend_raid()` (`systems/raiding.gd:430-436`) instead of resolving immediately, giving the player until the next tick to travel to the district and fight `Combat.start_defend_vein()` (`combat.gd:197`); if they don't show up in time, `_expire_pending_defend_raids()` (`raiding.gd:439-444`) resolves it exactly like the no-alarm path. This ticket is investigate-and-polish, not build-from-scratch: confirm the flow actually works end-to-end, and close the most likely real gap — the player isn't clearly told a defend-window has opened and is closing.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Confirm via test/manual play that installing an alarm and getting raided actually produces a pending-defend state reachable from the map/vein UI, not just a queued state with no visible entry point.
- [ ] Add/verify a clear, distinct notification when a defend-window opens (e.g. "Your vein's alarm went off — get there before it's too late"), separate from the generic raid-loss notification.
- [ ] Confirm the expiry path (`_expire_pending_defend_raids()`) also notifies clearly that the window was missed, distinguishing it from "raided, no alarm" so the player understands they had a chance and lost it vs. never had one.
- [ ] Manual check noted for the human: trigger a raid on an alarmed vein, confirm the defend prompt is visible and reachable, and confirm losing/winning that fight behaves as expected.
