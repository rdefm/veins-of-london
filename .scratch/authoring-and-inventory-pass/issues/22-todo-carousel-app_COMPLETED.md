# 22 — ToDo carousel app

**What to build:** The ToDo app becomes a carousel of questline pages in Family 2 phone chrome. The banner takes about 35% of height. Swiping the banner or tapping arrows changes page, and vertical goal scrolling is undisturbed. Arrows hide at each end, the carousel does not wrap, and dots show position with a pip for a new goal. The app opens on the most recently changed questline. The rent and deposit strip stays pinned above the banner. Done goals collapse and dim. Unstarted questlines show a locked banner with their empty text, and finished ones are stamped and desaturated. Tapping a goal does nothing. Banners resolve `assets/phone/todo/<questline>.png` with a default fallback, and crops of existing event art ship at those paths.

**Blocked by:** 21

**Relevant files:** `scenes/phone_apps/todo_app.gd`, `systems/todo.gd`, `assets/phone/todo/` (new), `assets/events/`, `docs/ui-vision.md`, `docs/adr/0005-event-image-asset-contract.md`, `tests/test_todo.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Swipe and arrows change page; arrows hide at each end; no wrap
- [ ] Dots and new-goal pips render, and viewing a page marks it seen through a system call
- [ ] Opens on the most recently changed questline
- [ ] Rent and deposit strip is pinned above the banner
- [ ] Done goals are collapsed and dimmed
- [ ] Collective ledger is collapsible
- [ ] Board page reads as a ladder
- [ ] Locked and finished banner states work
- [ ] Banner convention path wins and the default fallback works
- [ ] No Node state enters game state
- [ ] New strings are flagged `PROSE-REVIEW:`
- [ ] Human QA block lists swipe feel, banner layout and collapses
