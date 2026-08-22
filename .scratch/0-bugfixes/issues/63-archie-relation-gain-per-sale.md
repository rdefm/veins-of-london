# 63 — Archie relation gain per sale

**What to build:** James jobs already grant relation on completion (`Contacts.award_relation("james", 5)`, `systems/jobs.gd:140,160`) — confirmed working as designed, no change needed there. Archie item sales (`Economy.execute_sale()`, `systems/economy.gd:18-74`) currently never touch `contacts.archie.relation` at all — only a one-time `archieMotionPending` flag flip on first consumable sale (`economy.gd:56-58`). Add `Contacts.award_relation("archie", 2)` on each completed sale via Archie, per the human's direction (smaller than James's +5/job since sales happen far more often).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `Economy.execute_sale()` calls `Contacts.award_relation("archie", 2)` on every successful sale (ore or consumable), alongside existing sale logic.
- [ ] `docs/REFERENCE.md` §3.5/wherever sale mechanics are documented updated with the new relation constant.
- [ ] New test confirming a sale via Archie increases his relation by 2.
- [ ] Manual check noted for the human: sell an item via Archie, confirm his relation ticks up.
