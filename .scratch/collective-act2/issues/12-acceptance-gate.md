# 12 — Acceptance gate

**What to build:** One extended headless playthrough proving Act 2 is
completable end to end, T1 through T15 including T8a, with the sequencing
assertion and gate condition both verified. Full detail in
`.scratch/collective-act2/spec.md` §9 — read it before starting.

**Blocked by:** 11 (transitively, every other ticket in this feature).

**Status:** ready-for-agent

- [ ] `tests/test_playthrough.gd` extended to walk Act 2 end to end: T1→T15
      including T8a, driving all three Phase 1 choices (T5, T6, T7) down at
      least one branch each, completing `col_a2_nadia_supplies` before
      `col_a2_nadia_defend` activates (asserting the sequencing itself, not
      just end state) via real systems (`Crafting.attempt_craft` for each of
      the three recipe keys, `Raiding.resolve_defend_outcome`, `Cultivating`),
      and confirming the §7.4 gate condition is met and `col_a2_closer` fires.
- [ ] Unit seams from spec §9's table all covered: the three new `Objectives`
      evaluators (including `items_crafted_set`'s partial-checklist
      non-completion case, and idempotency), `col_a2_force_vein_loss`,
      `col_a2_ruin_site` (including the grep-based data-validity check),
      the two handler ops, the relation award table's thresholds/caps and
      daily-cap reset on `daily_tick`, and data validity (every new event
      JSON loads, every new flag/op/objective id referenced exists).
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` both green.
- [ ] Before closing this ticket, flag to the human that §11.1's playtest
      checkpoint (handler pricing §7.2, relation award table §7.3) is still
      outstanding — green tests are the acceptance gate for the tickets, not
      a substitute for that checkpoint.
