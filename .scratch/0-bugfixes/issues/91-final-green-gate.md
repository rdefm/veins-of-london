# 91 — Final green gate

**What to build:** Confirm the whole suite and lint are green after tickets 86–90.

**Blocked by:** 86, 87, 88, 89, 90

**Relevant files:** `scripts/run_tests.sh`, `scripts/check_all.sh`

**Status:** ready-for-agent

- [ ] `scripts/run_tests.sh` exits 0 with no FAIL lines
- [ ] `scripts/check_all.sh` fully clean
- [ ] Any leftover failure gets its own ticket instead of being waved through
