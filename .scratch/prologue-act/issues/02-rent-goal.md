# 02 — Rent goal row + rent-paid flag

**What to build:** The Prologue has one on-screen goal, "pay Monday's rent", and nothing tracks it today. The Monday weekly home bill is charged automatically in the daily tick (arrears if short). Add a flag set when a weekly home bill settles in full, usable by a `flag_true` objective, and a "Rent: £X / £Y" progress row (cash against the next bill due) in ToDo and BizBrief Today while a rent goal is active. The row is gated by a flag the Prologue sets and clears, mirroring the existing deposit-goal row. Row copy lives in data. Source: `docs/story-restructure.md` Prologue intro ("One goal on screen") and step 3 ("the rent gap is visible").

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/time_system.gd` (Monday home bill in the daily tick), `systems/home.gd` (bill due; `deposit_goal()` ~L299 as the pattern), `systems/daily_brief.gd` (`_deposit_goal_rows` ~L274), `data/daily_brief.json` (`depositGoal` row), `scenes/phone_apps/todo_app.gd` (deposit-goal line on top). REFERENCE §3.1, §3.3. Update REFERENCE and `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Paying the Monday bill in full sets the flag; a short pay (arrears) does not.
- [ ] Rent row shows cash / bill due while the goal flag is on, in ToDo and BizBrief; hidden otherwise.
- [ ] Row copy in data, flagged `PROSE-REVIEW:`.
- [ ] Tests cover full pay, short pay, row visibility.
