# 03 — Direction C social-card Feed

**What to build:** Feed looks like direction C's selected A-style professional-network feed, using live posts in dark social cards instead of generic game panels.

**Blocked by:** 01 — Shared brand, readable ink and tabs.

**Relevant files:** `.scratch/lodedinnit-visual-fidelity/spec.md`; `.scratch/lodedinnit/prototype-lodedinnit.html` (`hybridFeed`, `aFeed`, `.a .welcome`, `.a .post`, `.a .post-head`, `.a .engage`, `.a .comment`, `.c`); `.scratch/lodedinnit-ui/spec.md` §Feed; `scenes/phone_apps/lodedinnit_app.gd` (`_build_feed`, `_post_card`, `_avatar`); `systems/lodedinnit_feed.gd`; `scenes/components/ui.gd`; `theme/main_theme.tres`; `data/palette.json`; `docs/ui-vision.md` §10; `docs/CONTENT-GUIDE.md` §§3–4; `CODEMAP.md`; Feed presentation tests.

**Status:** ready-for-agent

- [ ] Below the shared brand/tabs, render direction C's compact Feed introduction: prominent near-white “Network activity” heading and smaller muted subtitle. Preserve the live empty-feed message when there are no posts.
- [ ] Each post uses a local dark card near `#303034`, thin cool-grey border near `#45454b`, ~14 px radius, ~14 px inset and ~11 px inter-card gap. No inherited cream `UI.card()` appearance or amber action styling.
- [ ] Card header: subdued ~36 px avatar, bold near-white author, small muted role/time meta. Body near-white, ~12 px with readable line height and clear separation from header and engagement row. All content comes from `LodedInnitFeed.card()`.
- [ ] Engagement counts sit below a hairline divider, left/right aligned with strong numerals and muted labels. Comments appear beneath with the mockup's inset/left-rule treatment and readable author emphasis. Handle zero, one and multiple comments cleanly.
- [ ] Maintain social cards rather than B's timeline; no decorative search/menu/composer controls absent from the approved live behavior. Hide visible scrollbar while retaining scroll. Headless Godot 4.7 checks pass for live post variants; on-device compare card density, hierarchy, colours and long-post wrapping with direction C.

## Comments
