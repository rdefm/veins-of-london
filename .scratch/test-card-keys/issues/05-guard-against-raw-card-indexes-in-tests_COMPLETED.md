# 05 — Guard against raw card indexes in tests

**What to build:** `check_all` flags new tests that hard-code card-index constants or loop on `cardIndex` without a cap, so the brittleness cannot creep back.

**Blocked by:** 02, 03, 04

**Relevant files:** `scripts/check_all.sh`, `scripts/lint_tokens.sh` (pattern for an allowlisted lint), `scripts/lint_tokens_allowlist.txt`, `CLAUDE.md` (Test hygiene).

**Status:** ready-for-agent

- [ ] Lint fails on `*_CARD := <int>` constants and uncapped `while` loops on `cardIndex` in `tests/`
- [ ] Remaining legitimate uses are allowlisted with a reason
- [ ] CLAUDE.md Test hygiene gains a one-line rule: address cards by key, cap walk loops
- [ ] `check_all` clean
