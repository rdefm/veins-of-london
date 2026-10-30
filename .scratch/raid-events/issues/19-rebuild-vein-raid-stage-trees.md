# 19 — Rebuild `vein_raid` as stage trees (placeholder prose)

**What to build:** `vein_raid` is rebuilt to the approved proposal (08). Each approach is a branch of stages with choices at each stage, using observation gates, item effects (including item options without a roll), alert raises and cover rolls, mid-raid fights from fight presets, and key links. The one-shot item approach rows from the earlier tickets (Wormhole, Pan's Rapture, Panic, Pandemonium, Powder) are folded into the stages where the proposal puts them. New and changed prose is placeholder. Real prose comes from the per-beat prose tickets 08 creates. Existing prose the proposal keeps is carried over unchanged.

**Blocked by:** 08 — Proposal (approved); 13 — Card links by key; 14 — Fight presets; 15 — Item options without a roll; 16 — Raid alert level; 17 — Cover roll on alert; 18 — Mid-raid guard bookkeeping.

**Relevant files:** `.scratch/raid-events/raid-variants-proposal.md`, `data/events/vein_raid.json`, `.scratch/writing-revamp/vein-raid-proposal.md` (storyboard draft, keep in sync or retire), `tests/test_raiding.gd`, `tests/test_event_items.gd`, `tests/test_event_content_lint.gd`, `CODEMAP.md`, REFERENCE.md §3.9a Event choice checks, §3.7b Open/Guarded round combat.

**Status:** ready-for-agent

- [ ] Event matches the approved proposal's branches, stages, gates, item effects and alert rules
- [ ] Content lint passes; all links are key links
- [ ] Tests (seeded): each branch reaches claim/loot on a clean run; each item path reaches its outcome; an alert raise changes later odds/options; a mid-raid fight win continues with fewer guards; a loss ends the raid
- [ ] CODEMAP row for `vein_raid.json` updated
- [ ] Human on-device check: play each branch clean and noisy via debug start
