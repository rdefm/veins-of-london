# 16 — Borrowed Time (implement)

**What to build:** Borrowed Time works as specced in 15. Using it adds a block today and books the tier's debt against tomorrow, visible to the player.

**Blocked by:** 15

**Relevant files:** `systems/time_system.gd`, `systems/active_effects.gd`, `systems/bag.gd`, `tests/test_time_system.gd`; REFERENCE §1.11.

**Spec:** see `15-borrowed-time-spec.md` (tier table, charge model, rollover debt, unlimited stacking, Rest loses unspent charges).

**Status:** ready-for-agent

- [ ] Loan and debt follow the 15 spec, including stacking, Rest and event rollover
- [ ] Tests set state directly (no loops on day/time conditions)
