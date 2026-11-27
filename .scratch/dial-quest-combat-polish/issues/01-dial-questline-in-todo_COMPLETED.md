# 01 — Dial questline in ToDo

**What to build:** James's Dial chain shows in the ToDo app as its own "Dial" questline page. The page stays hidden until James's first Dial text, then reveals one goal at a time:

1. Do James's paid bench job.
2. Gather the time calc James quoted, shown as "n of N". Stays open until James texts to say bring it, so spending calc beforehand never leaves a false tick.
3. Bring the calc to James.
4. Go to James's offer.
5. Go to the Dial creation lesson.
6. Seed your Dial at the bench.

The questline is done once the player's Dial exists. A failed seed leaves the last goal open. Seeding unlocks at the offer, so it can happen before the lesson: the lesson goal then stays open until the lesson is seen, and the page finishes after it.

The BizBrief Story row can surface these goals and sends the player to the right place. The page must be easy to extend: later work adds goals for finding and unlocking Movement recipes, crafting new Lenses and levelling the Dial. None of that is in this ticket.

No chain mechanics change.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `data/objectives.json` (existing questline entries; `activateFlag`/`completeFlag`/`briefAction`)
- `data/todo.json` (page label, subtitle, accent, `doneFlag`)
- `data/daily_brief.json` (`storyActions`)
- `data/dial.json` (`jamesQuest`)
- `data/events/james_dial_evaluation.json`, `james_dial_repair.json`, `james_dial_offer.json`, `james_player_dial_creation.json` (flags each step sets)
- `systems/objectives.gd` (goal types, `count_progress`, `refresh()`)
- `systems/todo.gd` (`get_pages`, `current_objective`, page order)
- `systems/james_dial.gd` (quoted calc: `flags.jamesDialCalcQty`; repair summons queued on daily tick)
- `systems/dial.gd` (`attempt_seed`, which does not refresh objectives today)
- `autoload/GameData.gd` (`_validate_objectives`, `OBJECTIVE_TYPES`), `autoload/GameState.gd` (flag defaults), `autoload/SaveManager.gd` (loading mid-chain saves)
- `.scratch/questlines/` (matching `dial.json` planning file for the storyboard tool)
- `tests/test_objectives.gd`, `tests/test_todo.gd`
- REFERENCE.md §3.5 Crafting & the Dial, §3.11 (ToDo)

**Status:** ready-for-agent

- [ ] No Dial page before James's first Dial text; page appears with that text
- [ ] Goals appear one at a time in chain order and tick off at each step
- [ ] Calc goal shows live "n of N" against James's quote, and ticks only when the bring-it text is queued
- [ ] Seeding success completes the last goal and finishes the page; failure leaves it open
- [ ] Seeding before the lesson: page finishes once both goals are satisfied
- [ ] A save loaded at any point in the chain, including with a Dial already seeded, shows correct goals without advancing a day
- [ ] Story row shows the current Dial goal in its turn and its action leads to the right place
- [ ] Matching questline planning file added; storyboard validation passes
- [ ] New goal types documented in REFERENCE.md; CODEMAP updated if file responsibilities change
- [ ] New copy drafted against CONTENT-GUIDE.md and flagged `PROSE-REVIEW:`
- [ ] Syntax check clean on touched files; tests cover each step; full suite passes
- [ ] Report lists on-device checks (page appears, goal order, count, banner fallback art, done state)
