# 03 — Diagnose and fix test_perks data_has_three_tiers_and_seventeen_perks

**Status:** done

**What to build:** `data_has_three_tiers_and_seventeen_perks` in `tests/test_perks.gd` fails with "got 6, expected 0". Diagnose whether perk data changed legitimately (update the test to the current shape/count, flagging it) or data/code regressed (fix it). Do not change perk numbers without asking: REFERENCE.md is canonical.

**Relevant files:** `tests/test_perks.gd`, `data/perks.json`, `systems/perks.gd`, REFERENCE.md perks section

- [x] Cause: "got 6, expected 0" was the validate_tables size assert (not perk count); 6 schema errors from raid_playground/blast flag, fixed by ticket 01. Perk data (17) unchanged.
- [x] Test passes (test_perks 25/0), matching REFERENCE.md
