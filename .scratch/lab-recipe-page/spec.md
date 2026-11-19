# Lab recipe page — notebook spread

Status: ready-for-agent

## Problem Statement

In the HQ Lab, tapping a recipe in the recipe book opens a generic dark scrolling card that has nothing to do with the book around it. It looks like a placeholder: grey/green range bars, hints floating between steps, a plain-text knowledge ladder, and the batch slider, total, Craft manually and Rewind piled into one long scroll. The player has to scroll to reach the actions and can't tell at a glance what they know, what they're missing, or why they can't reach a higher rank.

## Solution

Tapping a recipe turns the book to that recipe's own page, drawn on the same ring-bound paper art as the list:

- **Page 1 — the recipe.** The header repeats the list entry (icon frame, name, cost, stock, best rank) on ruled lines, so it reads as the same entry opened up. Below it, the procedure is written on the lines in ink: numbered steps, each with apparatus, calc and range, plus a small pencil scale under each step. An exact range is an inked bracket and a rough (≈) range is a hatched pencil smudge. Hints are pencilled margin notes attached to the step they're about.
- **Page 2 — knowledge.** The knowledge ladder as a checklist. Each rung row shows a tick or box, the rung name, exact/rough, and its max rank. Locked rungs have pencilled notes saying where to get them, plus any gate or insight. A closing line, "You can reach: rank N", gives the recipe's rank ceiling.
- **Bottom bar** (the existing dark bar below the book). On a recipe page it shows navigation (‹ Book, page counter, Prev/Next, Rewind) and three action buttons: **Craft manually**, **Auto-craft** and **Items**.
  - **Craft manually** docks the book under the Press and starts a hand run, as now.
  - **Items** opens the global Bag drawer (the same drawer as the top-right bag icon), so the player can use consumables (e.g. a Time Pearl or Be a Lady) without leaving the lab.
  - **Auto-craft** opens a slider sheet rising from the bar. In it the player picks how many to craft (1..max affordable) and sees the total calc. The sheet also has the multi-target toggle where that applies, and a confirm button. Confirming runs the existing batch craft.

The book's ore tabs stay visible and tappable on recipe pages. Tapping a tab returns to that ore's list.

## User Stories

1. As a player, I want tapping a recipe to turn to its own notebook page, so that the lab feels like one physical book rather than a popup.
2. As a player, I want the recipe page header to match the list entry I tapped (icon, name, cost, stock, best rank), so that I know I'm looking at the same recipe.
3. As a player, I want all text on recipe pages to sit on the ruled lines, so that it looks hand-written into the notebook.
4. As a player, I want each known step numbered, with apparatus, calc and range, so that I can follow the procedure at the bench.
5. As a player, I want exact ranges drawn as a crisp ink bracket on a small scale, so that I can see the target window at a glance.
6. As a player, I want rough (≈) ranges drawn as a hatched pencil band, so that I can tell imprecise knowledge from exact without reading the numbers.
7. As a player, I want insight steps (apparatus known, value unknown) shown as a "?" with no scale, so that I know a step exists without being told its value.
8. As a player, I want hints written as pencilled margin notes beside the step they concern, so that I can see which step they help with.
9. As a player, I want range tags from Prophet's Breath or a lesson talk-through kept on the step line, so that I know where that knowledge came from.
10. As a player, I want a second page for knowledge, so that the procedure page isn't crowded.
11. As a player, I want each rung shown as a ticked or empty box, so that I can see what I own at a glance.
12. As a player, I want owned rungs labelled exact or rough, so that I know whether learning more would sharpen them.
13. As a player, I want each rung's max rank shown, so that I understand what buying or earning it gives me.
14. As a player, I want locked rungs to say who sells them and what gate I haven't met yet, so that I know what to do next.
15. As a player, I want insights I've rolled shown on the locked rung they belong to, so that I know I'm partway there.
16. As a player, I want the Master technique row to show its source pointer, or "???" if it has none, so that I know it isn't for sale.
17. As a player, I want a "You can reach: rank N" line, so that I understand why my crafts cap where they do.
18. As a player, I want the knowledge page to update straight away when I gain a rung, so that I see my progress.
19. As a player, I want a Craft manually button always at the bottom of the screen, so that I don't have to scroll to start a hand run.
20. As a player, I want an Auto-craft button next to it, so that I can mass-produce without a hand run each time.
21. As a player, I want tapping Auto-craft to open a slider for how many to craft, so that I choose the quantity before committing.
22. As a player, I want the slider sheet to show total calc for the chosen quantity, so that I know what it will cost.
23. As a player, I want the confirm button in the sheet to show the quantity (e.g. "Craft ×4"), so that I know exactly what will happen.
24. As a player, I want the multi-target toggle inside the auto-craft sheet when the recipe offers it, so that all batch options sit together.
25. As a player, I want the multi-target gate line ("Best rank N unlocks multi-target.") shown when it's locked, so that I know how to unlock it.
26. As a player, I want Auto-craft disabled with "Craft one by hand first." until I've done a hand run, so that I understand the rule.
27. As a player, I want Auto-craft disabled with "Not enough calc." when I can't afford one, so that I know why.
28. As a player, I want to dismiss the auto-craft sheet without crafting, by tapping outside it or a cancel control, so that opening it is safe.
29. As a player, I want the existing batch toast after an auto-craft, so that I get the same confirmation as today.
30. As a player, I want any batch refusal reason shown on the recipe page, so that a failed craft isn't silent.
31. As a player, I want an Items button in the recipe page bar that opens my bag, so that I can use a consumable before crafting without leaving the lab.
32. As a player, I want closing the bag to return me to the same recipe page, so that I don't lose my place.
33. As a player, I want Rewind reachable from the recipe page bottom bar, so that undoing a run or batch stays one tap away.
34. As a player, I want ‹ Book in the bottom bar to return to the list page I came from, so that browsing is quick.
35. As a player, I want Prev/Next to flip between the recipe's two pages, so that the book behaves the same everywhere.
36. As a player, I want the ore tabs to stay tappable on a recipe page, so that I can jump to another ore's list.
37. As a player on a small phone, I want both pages to fit without scrolling for every recipe in the game, so that nothing is hidden.
38. As a player, I want ink and pencil colours that match the list pages, so that the book looks consistent.
39. As a player using a screen reader, I want the action buttons and rung rows to have readable names, so that the page is usable without sight.

## Implementation Decisions

- **Screen-only feature.** No new state, no save change and no system changes. Everything reads existing system functions: the known procedure, step region, rung rows, rank ceiling, max batch, batch, multi-target availability and Rewind. Screens stay read-only per the one-way data flow; button handlers call the existing system functions.
- **Recipe page replaces the dark recipe card.** The lab bench's recipe page is drawn on the RecipeBookPage component, like the list, instead of a MapCardStyle card. The page enum gains no new top-level page; the recipe page holds its own page index (0 = recipe, 1 = knowledge). Opening a recipe resets it to 0.
- **Baseline placement.** All recipe-page text uses RecipeBookPage's on-line placement. It puts a label's text baseline a fixed lift above a ruled line's top edge, given in art pixels, and scales with the art. The list entries already use this.
- **Art.** The current side-tabs art has four icon frames baked into the page, so it can't hold a procedure.
  - A new recipe-page asset is made by editing a **copy** of the existing side-tabs art (the original stays untouched for the list pages). Keep slot 0's icon frame and its ruled lines as the header. Replace the frames, squiggles and dividers of slots 1–3 with plain ruled lines matching the existing line colour and spacing, on the existing paper texture.
  - The new asset's ruled-line y positions are measured from the art and kept as a constant table. Its own ticket comes first, and every other ticket builds on it.
  - The pencil scale (ink bracket, hatched band) is drawn in code as a small gauge Control in the book's ink/pencil colours, not as art.
- **Knowledge ladder data.** The view reads the existing ladder rows (rung, label, ceiling, state, note) and the rank ceiling. The rung row's text template is not used on the notebook page; the page lays out label, state and ceiling in columns and puts the note on pencilled lines underneath. "You can reach: rank N" comes from the rank ceiling, shown as "—" for 0. New strings ("You can reach: rank %s", the exact/rough state words for this view, and any pencil-note framing) live in data/recipe_knowledge.json under the ladder block, not in code.
- **Bottom bar layout on a recipe page.**
  - Row 1: ‹ Book · page counter · Prev/Next · Rewind.
  - Row 2: **Craft manually**, **Auto-craft**, **Items**.
  - Close is not on the recipe page; ‹ Book then Close covers it.
  - On list pages the bar is unchanged.
- **Auto-craft sheet.** A sheet over the book, docked to the bottom bar, on a dim that cancels it. It contains the quantity slider (existing quantity-slider component; range 1..max batch; remembers the last picked quantity as now), the total line, the multi-target toggle and gate line when offered, and a confirm button labelled "Craft ×N" that runs the existing batch call and closes the sheet. When batch is blocked, the Auto-craft button itself is disabled and carries the reason (existing disabled-with-reason action button), so the sheet never opens in a blocked state.
- **Node names kept for tests.** The ladder region and per-rung row node names stay ("LadderRegion", "Rung_<rung>"), and so does the "Craft manually" button text. The batch confirm text becomes "Craft ×N", and the button that opens the sheet is "Auto-craft".
- **Items button.** Calls the existing Bag open action and nothing else. The global Bag drawer already renders over every screen, in management mode outside combat and item-hook events, so no new modal or drawer code is written. Recipe-page view state (recipe, page index) survives the drawer opening and closing.
- **Rewind.** Unchanged behaviour: one Rewind button opens the existing two-way choice and is disabled when nothing can be paid or rewound. It's hidden during a lesson, as now.
- **Docked notebook** (the cropped strip under the Press during a run) is unchanged in this spec.
- **CODEMAP** rows for the lab bench screen and RecipeBookPage are updated to describe the recipe spread, and the new art asset is added.

## Testing Decisions

- **One seam: the lab screen test** (the existing screen-level test that builds the HQ Lab bench, drives it through NodeQuery and asserts on labels and buttons). Tests check what the player sees and can press, never layout pixels or private helpers.
- Cases to cover:
  - Tapping a recipe shows page 1 with the recipe name, best rank and every known step's line.
  - Next turns to page 2. The ladder region has one row per rung, with the rung's state reflected, and the "You can reach" line equals the rank ceiling.
  - A rung grant redraws page 2. This test exists; adapt it.
  - Craft manually docks the book, as in the existing tests.
  - Auto-craft is disabled before a hand run, with the reason; it's enabled after one.
  - Tapping Auto-craft opens the sheet. Confirming "Craft ×1" crafts (stock rises by the batch outcome) and closes the sheet. Cancelling crafts nothing.
  - Multi-target toggle appears only for offered recipes.
  - Rewind button present and disabled when nothing to pay. This test exists; adapt it.
  - ‹ Book returns to the list page and tab the player came from.
  - Items opens the Bag (the drawer-open flag is set); closing it leaves the same recipe page showing.
- The knowledge system already has its own unit tests for ladder rows and ceilings; no new system tests are needed unless a string moves into data.
- **Prior art:** the existing lab screen tests (recipe card, ladder region, batch, Rewind cases), and the lab bench test for the book list and tabs.

## Out of Scope

- Any change to lab mechanics, the rank formula, batch rules, knowledge rungs, prices, gates or insight rolls.
- Buying rungs from the recipe page (a "£ cost" tag that opens James's or Wren's shop). That's possible later work.
- Page-turn animation.
- Restyling the docked run notebook or the run/result card.
- The Experiments notebook.

## Further Notes

- Done already, outside this spec: list entries on the book's index pages now sit on the ruled lines, via the on-line placement helper and a measured per-slot line table.
- New player-facing strings (pencilled lock notes framing, "You can reach", the sheet's confirm and cancel labels) must be flagged PROSE-REVIEW and follow docs/CONTENT-GUIDE.md.
- Rewind stays on the bar's navigation row.
