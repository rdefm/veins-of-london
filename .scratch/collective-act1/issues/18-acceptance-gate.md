# 18 — Acceptance gate

**What to build:** One extended headless playthrough proving Act 1 is
completable end to end with every flag landing, plus a second variant proving
the S14 decline branch still grants membership later. This is the acceptance
criterion for the act as a whole — full detail in
`.scratch/collective-act1/spec.md` §12.1 — read it before starting.

**Blocked by:** 10, 12, 14, 15, 16, 17 (transitively, every other ticket in
this feature).

**Status:** ready-for-agent

- [ ] `tests/test_playthrough.gd` walks tutorial end → S1 → S2 → S3 → S4 → all
      three threads (driven by really calling `Sites.prospect()`, `Economy`
      sales, `Cultivating.cultivate()`, `VeinTrade.sell_to_faction()` — not
      shortcuts) → S14 → membership, asserting every flag in §10.2 lands.
- [ ] A second test variant walks the decline branch at S14 and confirms the
      deferred-join follow-up later grants membership.
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` are both green.
- [ ] Before closing this ticket, flag to the human that §14.1's playtest
      checkpoint (a human playing days 1–14, since Archie's cut rescale and
      the Collective lane's arrival both raise early income at once) is still
      outstanding — green tests are the acceptance gate for the tickets, not a
      substitute for that checkpoint.
