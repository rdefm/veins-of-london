# 10 — HQ missed-defend repel boost

**What to build:** When HQ guards roll to repel a pending home raid the player missed, the HQ kit boosts the chance exactly as vein kits do: per-type strengths, the 0.90 cap with kit, and one unit of each active type used on success or failure. A failed repel leaves the rest of the kit in place, and raid loss stays ore-only. A successful repel that used kit appends "They went through <items>."

**Blocked by:** 05 — Vein missed-defend repel boost; 09 — HQ guard kit state.

**Relevant files:** `systems/home.gd` (`guard_repel_chance` ~104, `_guards_repel_pending_raid` ~112, `_apply_raid_loss`), the shared kit-bonus helper from ticket 05, `tests/test_home.gd` (or the existing home raid tests). Spec §HQ guard kit. REFERENCE.md HQ raid section / §3.12.

**Status:** ready-for-agent

- [ ] With a seeded Rng, the HQ repel chance includes the kit bonus and the raised cap. One of each active type is used on both outcomes.
- [ ] A failed repel leaves the unused kit intact, and raid loss still takes ore only.
- [ ] 0 HQ guards means no roll and no spend. Suffix flagged PROSE-REVIEW. REFERENCE is updated.
