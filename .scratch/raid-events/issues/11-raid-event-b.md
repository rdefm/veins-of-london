# 11 — Raid event B: build as stage trees with placeholder prose

**What to build:** The second new vein-raid event from the approved proposal (ticket 08), built as data. Each approach is a branch of stages with choices at each stage. It includes observations, observation gates, item effects (including item options without a roll), alert raises and cover rolls, mid-raid fights from the event's fight presets, failure paths and the claim/loot card. Cards link by key. All prose is placeholder. The event is added to the raid event pool, so a vein raid can draw it.

**Blocked by:** 08 — Proposal (approved); 09 — Raid event pool; 13 — Card links by key; 14 — Fight presets; 15 — Item options without a roll; 16 — Raid alert level; 17 — Cover roll on alert; 18 — Mid-raid guard bookkeeping.

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md`, `data/events/vein_raid.json` (pattern, after 19 if done), `data/events/<event-b>.json` (new), raid pool data from 09, `tests/test_raiding.gd`, `tests/test_event_content_lint.gd`, `CODEMAP.md`, REFERENCE.md §3.9a Event choice checks, §3.7b Open/Guarded round combat.

**Status:** ready-for-agent

- [ ] Event matches the approved proposal's branches, stages, gates, item effects and alert rules
- [ ] In the raid pool; content lint passes
- [ ] Tests (seeded): each gated choice locked/unlocked as designed; each branch reaches claim/loot on a clean run; an alert raise changes later odds/options as designed; a mid-raid fight win continues with fewer guards
- [ ] CODEMAP updated for the new data file
- [ ] Human on-device check: play the event via debug start through each branch, clean and noisy
