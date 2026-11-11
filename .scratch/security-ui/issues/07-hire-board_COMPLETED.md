# 07 — Hire board redesign

**What to build:** the hire board modal rebuilt.

- Header: "Hire board", "New board <next Monday date>", and one muted line: hiring pays this week's share of the wage today; new guards start in Reserve.
- Each candidate card: full name + level badge; wage per week on the right (when a wage trait changes it, the base level wage struck through beside it); one row per trait with sign (+ / − / ±), label and effect line from data; "↺ Worked for you before" tag for former guards; a "Hire <first name>" button, disabled with `hire_block_reason` shown when blocked.
- A hired slot renders as a dashed card "Hired <short name> — refills Monday" (needs the hired guard's name kept on the empty slot, or "Hired — refills Monday" if the board doesn't keep it; don't add state just for this without asking).

Mockup: https://claude.ai/artifact/3F5zB6ctS4FBERj2k4SqDx (Hire artboard).

**Blocked by:** 03 — Guards tab rows and shared guard widgets.

**Relevant files:** `scenes/modals/guard_hire_modal.gd` (`build`, `_card`), `systems/muscle.gd` (`board`, `roll_board_if_due`, `hire_block_reason`, `hire`, `wage`, `level_wage`), `scenes/components/guard_widgets.gd`, `data/muscle_traits.json`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Cards show signed traits with effect lines, wage with struck base when modified
- [ ] Returning guard tag; hired slot card
- [ ] Next-board date correct across the week
- [ ] Hire still pays the advance via `Muscle.hire`
- [ ] check_all clean; full suite green
- [ ] PROSE-REVIEW: header lines, slot card text
- [ ] On-device checklist in the report
