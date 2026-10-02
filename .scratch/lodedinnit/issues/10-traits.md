# 10 — Traits

**What to build:** Some candidates have a trait with a small gameplay effect and their own feed flavour. `distracted` (Saoirse, Ray) skips their block action with chance 0.2; a distracted producer skips their whole block of crafting. `eager` (Tomasz) earns role XP × 1.25. Trait-flavoured post variants: distracted posts trail off mid-thought, eager posts are over-enthusiastic hustle.

**Blocked by:** 04 — LodedInnit app: hire an open candidate; 08 — Feed: one post per block.

**Relevant files:** `data/hiring.json` `traits`, `systems/rooms.gd` (`process_staff_block`, `_run_producers`), `systems/contacts.gd` (`award_contact_xp`), `data/lodedinnit.json`, `systems/lodedinnit_feed.gd`, spec §7, §10 R6/R10, REFERENCE.md §3.10.

**Status:** ready-for-agent

- [ ] Skip chance and XP multiplier read from data; tested with a seeded Rng
- [ ] 2 trait variants per trait-bearing candidate in the feed pools
- [ ] PROSE-REVIEW: trait posts
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: profile shows the trait; trait posts read distinctly
