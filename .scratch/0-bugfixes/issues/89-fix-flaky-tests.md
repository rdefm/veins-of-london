# 89 — Fix the flaky tests

**What to build:** Find and remove the nondeterminism in tests that failed in some full-suite runs only: `an_auto_offered_toggle_spends_on_fail_and_rewind_refunds` and `blast_raises_alert_one_tier_from_its_profile_clamped_and_skeleton_key_does_not`. Likely unseeded RNG or state leaked between cases.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/` (grep both case names), `tests/test_base.gd` (`run_case`), the systems under test found via that grep

**Status:** ready-for-agent

- [ ] Cause identified for each
- [ ] Each case's file run 3x alone and 3x in the full suite with no failure
