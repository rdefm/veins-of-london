# LodedInnit direction C UI

Status: approved by the human 2026-10-02 for ticket breakdown and publication.

## Visual reference

`.scratch/lodedinnit/prototype-lodedinnit.html`, direction C (`?variant=C`): B's compact People directory and profile, A's social-card Feed, LodedInnit plum/copper brand and prototype logo. This is a presentation reference; live game state and canonical mechanics/data remain authoritative. Keep the existing simulated phone frame and status bar. Place Feed/People tabs directly below the brand header on both tabs.

## People

Show the live enabled-role roster in compact Cultivator/Crafter groups with name, headline, availability, level/cap and weekly wage. Preserve candidate navigation. Role filters to All/Cultivators/Crafters. Ore specialism filters to All or one of the five canonical ores, matching a candidate with that speciality; combine with Role. Wage starts in roster order; first tap sorts highest to lowest, second lowest to highest, then alternates. Keep role groups and sort within each visible group. Counts and statuses reflect the current filtered data. Empty matches show a clear message. Controls are functional; omit the mockup's decorative `⋯` menu. Collapsible role groups are a future opportunity, not part of this pass.

## Profile and hire

Use direction C's profile and lower hire area. Keep live role/status, headline/about, level/cap, weekly wage, all speciality pips, room/seat availability, blocked hire reason, and first-week wage. Preserve `Hiring.hire`, the float top-up prompt with Yes/No, and return to People with view filters intact. Keep app unlock at `bizA1JamesJoined`.

## Feed

Existing `.scratch/lodedinnit/issues/08-feed-post-per-block.md` owns feed generation and the direction C social-card rendering; `.scratch/lodedinnit/issues/09-hire-status-posts.md` owns later status posts. The redesign's shared brand/tabs should precede Feed implementation. Sample mockup posts are not canonical data or final prose.

## Sources

- `.scratch/lodedinnit/hiring-spec.md` §§3, 4, 6, 9, 10
- `docs/REFERENCE.md` §3.10 Hiring and §2 state paths
- `docs/ui-vision.md` §10 phone content and app-specific exceptions
- `docs/CONTENT-GUIDE.md` §3–4 for new copy
