# 103 — General phone-tab shortcut for pin-gated quest-givers

**What to build:** Some quest-givers (starting with Des's Act 1 prospecting/seeding thread) are currently reachable only by finding their map pin. Add a phone-tab shortcut, in the same spirit as Archie's quests/events (a button on the contact's phone card that starts the event directly, no travel required), so any quest-giver whose event is currently gated purely on a map pin also gets a phone-reachable trigger. Tapping the shortcut starts the event immediately — it does not require the player to be in the relevant district, and does not merely point at the map pin. The map pin itself remains as an additional, alternate way to reach the same event; this is a second path, not a replacement.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Des's prospecting event (and the follow-on seeding event) can be started directly from a button on his phone contact card, with no travel required.
- [ ] The map pin path for the same events continues to work unchanged (this is an additional access path, not a replacement).
- [ ] The mechanism is general — driven by the same pin-gating data already used by the map (not hardcoded to Des alone) — so future pin-gated quest-givers pick it up by declaring the same data, without new UI code.
- [ ] Regression test covering: starting the event via the phone shortcut, and starting it via the map pin, both leading to the same event/flag outcome.
