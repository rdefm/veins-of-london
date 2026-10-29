# 10 — Raid event A: build with placeholder prose

**What to build:** The first new vein-raid event from the approved proposal (ticket 08), built as data: its observations, approaches, observation gates, item effects, fight-start payloads, beats and failure paths, with placeholder prose. Added to the raid event pool, so a vein raid can draw it.

**Blocked by:** 04 — Wormhole / Pan's Rapture; 05 — Panic / Pandemonium; 06 — Time Pearl; 08 — Proposal (approved); 09 — Raid event pool.

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md`, `data/events/vein_raid.json` (pattern), `data/events/<event-a>.json` (new), raid pool data from 09, `tests/test_raiding.gd`, `tests/test_event_content_lint.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Event matches the approved proposal's approaches, gates and item effects
- [ ] In the raid pool; content lint passes
- [ ] Tests: each gated approach locked/unlocked as designed; each item path reaches its outcome (seeded)
- [ ] CODEMAP updated for the new data file
- [ ] Human on-device check: play the event via debug start through each approach
