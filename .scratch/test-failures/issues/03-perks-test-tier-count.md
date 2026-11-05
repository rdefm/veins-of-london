# 03 — Diagnose and fix test_perks data_has_three_tiers_and_seventeen_perks

**Status:** ready-for-agent

**What to build:** `data_has_three_tiers_and_seventeen_perks` in `tests/test_perks.gd` fails with "got 6, expected 0". Diagnose whether perk data changed legitimately (update the test to the current shape/count, flagging it) or data/code regressed (fix it). Do not change perk numbers without asking: REFERENCE.md is canonical.

**Relevant files:** `tests/test_perks.gd`, `data/perks.json`, `systems/perks.gd`, REFERENCE.md perks section

- [ ] Cause identified and noted in the ticket
- [ ] Test passes, matching REFERENCE.md
