# 05 — Crafters work until done or out of ore, not one attempt per block

**What to build:** Replace the "one craft attempt per time block" Producer rule.

- At each staff step, a Production-role crafter keeps attempting crafts until every order/condition is satisfied, or until they lack the ore to make the next item. They then stop and wait for the next block.
- "Satisfied" means all Production targets are met (e.g. "maintain stock of 10 Time Pearls" → stops once stock is 10) and active contract needs covered, in the existing Production priority order.
- Failed attempts consume ore as they do today and count as attempts. XP per attempt is unchanged.
- Everything resolves instantly within the block's staff step.
- Ore comes from shared stock only, never the personal stash (unchanged).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/rooms.gd` (per-block staff step, Production targets/priority), crafting resolution system, `systems/morning_accounts.gd` (per-block staff output accumulation), `tests/test_rooms.gd`, REFERENCE.md §3.10 "Producer (per block)", §3.5 Crafting & the Dial, `.scratch/biz-act1/spec.md` story 50.

**Status:** ready-for-agent

- [ ] With ore for N items and a target above stock, a crafter makes attempts until the target is met or ore runs out, within one block.
- [ ] Stops exactly at the target (stock 10 → no more attempts). Also stops when the next recipe's ore is short.
- [ ] Multiple crafters share stock deterministically (document the order), with no double-counting of targets.
- [ ] Loop is bounded: can't spin forever on zero-cost or zero-progress edge cases.
- [ ] Morning accounts still show accurate per-block output.
- [ ] REFERENCE.md "Producer (per block)" and spec story 50 are rewritten to the new rule.
- [ ] Tests cover target stop, ore-out stop, failures consuming ore, and multi-crafter.
