# 10 — Deposit goal progress

**What to build:** When a story flag (set by the flat-raid debrief) is on, the player sees a savings goal, "Deposit: £X / £Y", towards the target home's deposit. It shows in the ToDo app and on BizBrief Today while they play the Collective quests, and clears once they've moved. Source: `docs/story-restructure.md` "Early Act 1 beats", "Features to build" item 5.

**Blocked by:** 09 — Move deposit on rented moves.

**Relevant files:** `systems/todo.gd`, `scenes/screens/todo*.gd`, the BizBrief Today screen/system, `systems/home.gd` (deposit amount), `systems/events.gd` (flag/op to set the goal target). REFERENCE §2 flags/state paths.

**Status:** ready-for-agent

- [ ] An event op or flag sets the goal and its target tier. The amount comes from 09's deposit rule, not a hard-coded number.
- [ ] ToDo and BizBrief Today show current cash against the deposit, updating as cash changes.
- [ ] The goal completes and hides when the player rents or buys the target tier or better.
- [ ] Tests cover set, progress readout and completion. The human checks both displays on device.
