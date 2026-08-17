# 06 — Relocate Rest and the home-raid trigger to HQ

**What to build:** Move the only Rest action and the one-shot home-raid trigger from the old home screen to HQ, so the game never has a window with no way to rest or to receive the raid event, once the home screen is later deleted.

**Blocked by:** None — can start immediately. Must land before ticket 12.

**Status:** ready-for-agent

- [ ] Player can rest (end day, heal) from an action on the HQ screen, calling the same rest logic as today
- [ ] HQ's screen-ready logic checks the home-raid one-shot flag before building its UI and returns early if the event starts (mirrors the old home screen's check-before-refresh pattern, since starting the event navigates away and frees the node)
- [ ] Raid event fires on the player's next HQ visit after the trigger condition is met, exactly once
- [ ] Old home screen's rest button and raid-trigger check are left in place until ticket 12 removes the screen entirely (this ticket adds the HQ path, it does not yet delete the old one)
- [ ] Tests cover: Rest action produces identical effects to today; one-shot raid trigger fires exactly once on qualifying HQ visit and never again
