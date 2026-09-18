# 06 — Lab bench: pan model, stops, mode fork

**What to build:** The lab equipment zone opens the bench sub-view: one wide
plate (1170×844 displayed, authored 585×422, 2× nearest) with three
snap-to focal stops — books, ore containers, apparatus — stepped by arrows,
no free scrolling. The bench opens on the books stop with two notebooks,
Recipes and Experiments; tapping one sets the mode, the chosen notebook
stays visibly open for the session, and tapping it again returns to the
fork. This ticket delivers navigation and mode state only — no crafting yet;
it replaces `lab.gd`'s entry point but Recipes/Experiments content and
apparatus interaction land in ticket 07.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Bench opens from the Lab zone as a full-bleed sub-view
- [ ] Three stops (books, ore, apparatus) with arrow-stepped navigation, no swipe/scroll
- [ ] Books stop shows the two notebooks; tapping one sets and persists the session's mode
- [ ] Tapping the held notebook returns to the fork; mode can be switched freely
- [ ] No crafting logic wired yet — this ticket is navigation and mode state only
