# 13 — User-story audit and sign-off

**What to build:** Check the finished work against all 95 user stories in the spec. Each story gets a pass, a gap, or a note that it needs human on-device QA, with the evidence: a test, a sim result or a named check. Gaps are reported to the human, not fixed here unless trivial. The report ends with one on-device QA list for the human.

Spec: `.scratch/london-market/spec.md`, all user stories, "Testing Decisions", "Out of Scope".

**Blocked by:** 09, 10, 12

**Relevant files:** `.scratch/london-market/spec.md`, `.scratch/london-market/balance-report.md`, `docs/REFERENCE.md`, `CONTEXT.md`, `CODEMAP.md`, `tests/test_market.gd`, `tests/test_faction_sim.gd`, `tests/test_soho.gd`, `tests/test_offers.gd`, `tests/test_map_pins.gd`

**Status:** ready-for-agent

- [ ] All 95 stories are marked pass, gap or human QA, with evidence, in `.scratch/london-market/story-audit.md`
- [ ] Out-of-scope items were not built
- [ ] REFERENCE.md §1.8, §3.4, §3.6, §3.13 and the daily order match the code
- [ ] `CONTEXT.md` defines London market, Soho Marketplace and Guild Marketplace
- [ ] Full test suite and `scripts/check_all.sh` are clean
- [ ] The on-device QA list covers the Soho pin, Trade mode and fee rung display
- [ ] Balance reports from tickets 11 and 12 have human sign-off
