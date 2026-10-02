# 09 — Hire-status posts

**What to build:** Market events show up in the feed as extra posts, on top of the per-block post: hired by you, let go, poached by/from a faction, and flipped to employed or open. Each event kind has templates filled with `{name}`/`{employer}`.

**Blocked by:** 07 — Factions poach your staff; 08 — Feed: one post per block.

**Relevant files:** `data/lodedinnit.json` (status templates), `systems/lodedinnit_feed.gd`, `systems/hiring.gd`, spec §6.3, §10 R6.

**Status:** ready-for-agent

- [ ] Every status change from tickets 04–07 emits exactly one status post
- [ ] 2 templates per event kind
- [ ] PROSE-REVIEW: templates
- [ ] CODEMAP updated
- [ ] Human check: hire, let go, and a poach each produce a feed post
