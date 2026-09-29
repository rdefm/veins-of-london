# 09 — HQ guard kit: state + stocking

**What to build:** HQ guards get a kit. `home.guardKit` (tier-bucketed, with `{}` backfilled on old saves) holds allowlisted items. Capacity is `Home.get_guard_count() × guardKit.hqSlotsPerGuard` (3), with the same over-capacity, idle and refusal rules as vein kits. GuardKit stock/unstock accept the HQ as a target. The HQ Guard Kit screen gets an HQ row at the top, and the HQ security zone gets a kit row, both opening the shared stocking sheet. Guards walking leaves the kit in place.

**Blocked by:** 01 — Guard kit core; 03 — HQ Guard Kit screen.

**Relevant files:** `systems/guard_kit.gd`, `systems/home.gd` (`get_guard_count`), `systems/guard_upkeep.gd` (~line 70 HQ count/drop), SaveManager, `scenes/screens/hq_door.gd`, the ticket 03 screen, the ticket 02 sheet, `tests/test_guard_kit.gd`, `CODEMAP.md`. Spec §HQ guard kit. REFERENCE.md §1.6, §2.

**Status:** ready-for-agent

- [ ] `home.guardKit` round-trips through save, and an old save gets `{}`.
- [ ] HQ stock/unstock follow the vein rules with 3 slots per HQ guard. Stocking with 0 HQ guards is refused, and returning is always allowed.
- [ ] Dropping an HQ guard keeps the kit, and the excess goes inactive.
- [ ] The HQ row and the security-zone row open the sheet for the HQ target. New strings flagged PROSE-REVIEW, plus an on-device check block. REFERENCE and CODEMAP are updated.
