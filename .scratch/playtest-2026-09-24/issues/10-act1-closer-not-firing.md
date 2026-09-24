# 10 — Act 1 Collective closer doesn't fire

**What to build:** After all three Act 1 Collective threads are done, the closer (gathering at Hakim's, then he gives you a vein) always queues once its gate is met, so Act 2 can start. Reported: completed Act 1, closer never triggered. Likely cause: the closer check only runs right after an event completes; if Collective relation is under 25 at that moment (or the last thread flag flips outside an event), it's never checked again — unlike the Act 2 intro, which has a daily-tick backstop. Confirm, then add a backstop so the closer queues whenever the gate becomes true.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/collective.gd` (`maybe_trigger_closer`, `maybe_trigger_act2_intro`), `systems/events.gd`, `systems/time_system.gd` (daily tick), `systems/objectives.gd`, `systems/messages.gd`, `data/events/col_a1_closer.json`, `data/events/col_a1_nadia_done.json`, `data/objectives.json`.

**Status:** ready-for-agent

- [ ] Cause confirmed and noted under `## Comments`
- [ ] Test: threads done with relation < 25 → no closer; relation back ≥ 25 → closer queued at next backstop
- [ ] No double-queue; no re-fire after `colA1Complete`
- [ ] Act 2 intro still follows the closer
