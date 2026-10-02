# 08 — Feed: one post per block

**What to build:** LodedInnit's Feed tab shows faux posts from candidates and hires (individuals only). One post is rolled per time block at the staff block step (Rewind-safe), picked from a weighted pool of authors who still have unused posts. A post isn't repeated until its author's pool is used up. Each post has a rolled likes count and 0–2 canned comments from other individuals; these are display only. The feed is capped at 50 entries, and the app icon badges unseen posts. Each post records its author `kind` so faction/company authors can be added later.

**Blocked by:** 04 — LodedInnit app: hire an open candidate.

**Relevant files:** new `data/lodedinnit.json` (voice pools, comments), new `systems/lodedinnit_feed.gd`, `systems/rooms.gd` (`process_staff_block`) or the `systems/time_system.gd` block step, `systems/phone_apps.gd` (badge), lodedinnit app, `docs/CONTENT-GUIDE.md`, spec §6.1/§6.2/§6.4, §9 `feed`/`feedSeen`, §10 R6, REFERENCE.md §2.

**Status:** ready-for-agent

- [ ] ~6 posts per candidate voice, ~12 shared comments
- [ ] Exactly one post per block; no repeats until an author's pool is exhausted; cap 50
- [ ] Badge = posts after `feedSeen`; opening the Feed clears it
- [ ] Deterministic under Rewind
- [ ] PROSE-REVIEW: `data/lodedinnit.json`
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: Feed shows posts with likes/comments; badge appears and clears
