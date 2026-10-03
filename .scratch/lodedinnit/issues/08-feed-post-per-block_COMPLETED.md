# 08 — Feed: one post per block

**What to build:** LodedInnit's Feed tab shows faux posts from candidates and hires (individuals only). One post is rolled per time block at the staff block step (Rewind-safe), picked from a weighted pool of authors who still have unused posts. A post isn't repeated until its author's pool is used up. Each post has a rolled likes count and 0–2 canned comments from other individuals; these are display only. The feed is capped at 50 entries, and the app icon badges unseen posts. Each post records its author `kind` so faction/company authors can be added later. Render the feed in direction C's social-card layout, using live data rather than the mockup's sample posts.

**Blocked by:** 04 — LodedInnit app: hire an open candidate; `.scratch/lodedinnit-ui/issues/01-people-directory-and-controls.md` — direction C brand and shared tabs.

**Relevant files:** `.scratch/lodedinnit/prototype-lodedinnit.html` (direction C, pane `02 · Feed`, specifically `hybridFeed()`/`aFeed()` and `.a .post`/`.c` styles; presentation reference only), `.scratch/lodedinnit-ui/spec.md` §Feed, new `data/lodedinnit.json` (voice pools, comments), new `systems/lodedinnit_feed.gd`, `systems/rooms.gd` (`process_staff_block`) or the `systems/time_system.gd` block step, `systems/phone_apps.gd` (badge), `scenes/phone_apps/lodedinnit_app.gd`, `docs/CONTENT-GUIDE.md`, `.scratch/lodedinnit/hiring-spec.md` §6.1/§6.2/§6.4, §9 `feed`/`feedSeen`, §10 R6, `docs/REFERENCE.md` §2, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] ~6 posts per candidate voice, ~12 shared comments
- [ ] Exactly one post per block; no repeats until an author's pool is exhausted; cap 50
- [ ] Direction C Feed: the LodedInnit brand header, Feed/People tabs directly below it on both tabs, `Network activity` intro, and scrollable social cards. Each card shows author initials/avatar, name, role/status and a time derived from its stored day/block, post body, rolled likes, comment count, and the 0–2 canned comments. Newest post first.
- [ ] Any displayed count, time, author and text comes from game state/data; the three sample posts and counts in the HTML are not hardcoded. Zero posts keeps an informative empty state. Likes/comments are read-only; do not add posting, liking or commenting actions.
- [ ] The same card renderer can display ticket 09's later hire-status posts without a second Feed layout.
- [ ] Badge = posts after `feedSeen`; opening the Feed clears it
- [ ] Deterministic under Rewind
- [ ] PROSE-REVIEW: `data/lodedinnit.json`
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: empty and populated Feed match direction C; author, time, likes and comments update from real posts; badge appears and clears; switching tabs keeps navigation usable
