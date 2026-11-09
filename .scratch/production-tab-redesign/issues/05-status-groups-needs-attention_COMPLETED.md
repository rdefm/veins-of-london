# 05 — Status groups and "Needs attention"

**What to build:** The recipe list is split under headers (small label, count, hairline): Needs attention, Custom, Following defaults. Empty groups hide. A recipe is in Needs attention when it is below its target and no working producer can afford one attempt from shared ore; its card shows a warning chip naming the short ore (e.g. "Out of Time ore") instead of Following/Custom and sorts above the others. A recipe with an override and an ore shortage appears once, under Needs attention. The ore-short check is extracted from the Brief's logic into one shared system function used by both the Brief and Production, with Brief behaviour unchanged. A Brief ore-short row that deep-links to a recipe opens that card expanded and scrolls it into view.

**Blocked by:** 02 — Recipe card.

**Relevant files:** `systems/daily_brief.gd` (`_ore_short_rows`); `systems/rooms.gd` (`effective_lab_target`, `producible_recipes`); `systems/lab.gd` (`base_calc`); `systems/phone_nav.gd`; `scenes/phone_apps/bizbrief_app.gd` (`_build_production`, `_recipe_anchors`); `tests/test_phone_bizbrief.gd`, `tests/test_daily_brief.gd`; `CODEMAP.md`; mockup `.scratch/production-tab/production-redesign-mockup.html`.

**Status:** ready-for-agent

- [ ] Three groups render in order with counts; empty groups hidden.
- [ ] One shared ore-short function serves Brief and Production; existing Brief tests pass unchanged.
- [ ] Needs attention cards show the short ore in the chip; overridden + short recipes appear once.
- [ ] Deep link from a Brief row expands and scrolls to the card.
- [ ] Tests cover grouping and the deep link; all tests pass.
