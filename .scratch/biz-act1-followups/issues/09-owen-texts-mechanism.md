# 09 — Owen's random texts: scheduler and reply choices

**What to build:** From Owen joining, Owen sends the player a random text roughly every 2–3 days. No texts while he isn't working (owed wages / not working per the payroll working check).

- **Cultivating questions:** the player taps one of 2–3 reply options. Choosing the right answer gives Owen cultivating XP (reuse `cultivatorActionXp`, 2), and the others give nothing. Owen's follow-up line reacts either way.
- **Flavour texts:** humour, youth, naivety. They still have tappable replies but no mechanical effect.
- **Vein templating:** texts can template in real state, e.g. the name/district of a vein currently on Owen's cultivator list. A text needing a vein is skipped if he has none.
- **Repeats:** each text plays once until the pool is exhausted, then repeats are allowed (least-recently-used first).

Ship the mechanism with 2 sample texts (1 XP question, 1 flavour). Full content is ticket 10.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/messages.gd` (queue_pending, threads), `scenes/phone_apps/messages_app.gd` (action bar / reply choices), `systems/contacts.gd` (Owen skills/XP, caps), `systems/payroll.gd` (`is_working`), `systems/rooms.gd` (Owen's `cultivatorVeins`), `systems/business_quest.gd` or a new small system for the scheduler, the rollover hook in the time system, a new data file for the text pool, `tests/test_messages.gd`, REFERENCE.md §3.10 "Staff roles", `docs/CONTENT-GUIDE.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Scheduler fires at a randomised 2–3 day interval from Owen joining, paused while he isn't working. Deterministic under a seeded RNG for tests.
- [ ] Reply choices are tappable in Messages. The correct answer grants XP (respecting his skill cap). Owen replies to either choice.
- [ ] Vein templating uses a real assigned vein. The text is skipped if none.
- [ ] Played-text tracking lives in the pure state tree. Save/Rewind-safe.
- [ ] Data-driven pool with a validator.
- [ ] Two sample texts, flagged `PROSE-REVIEW:`.
- [ ] Tests cover cadence, the pause rule, XP on the right answer, no XP on the wrong one, and templating.
