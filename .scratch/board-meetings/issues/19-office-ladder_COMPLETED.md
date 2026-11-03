# 19 — Office ladder

**What to build:** the **Office** ladder starting with "Get a proper office"; its reward can move the meeting venue from James's workshop to the player's HQ. Office tiers beyond what this ladder defines are out of scope. Introduces office rewards (objects) if the ladder needs them. Voice for the ladder to be confirmed at triage.

**Blocked by:** 05 — Monday meeting event + rollover + Act 1 hand-off; slice 1 (01–14) playtested and tuned

**Relevant files:**
- `systems/home.gd`, `systems/rooms.gd`, `data/home.json`, `data/hq_visuals.json`
- `systems/board_meetings.gd`, `data/board.json`, meeting event data (venue)
- Spec: stories 55, 73, 79; `.scratch/hq-rooms/`

**Status:** needs-triage

- [ ] Venue switch driven by state; meeting event reads it
- [ ] Rungs open from real state; tests
