# 05 — Vein missed-defend repel boost

**What to build:** When a player vein's guards roll repel for a raid the player missed (the missed-defend window or Leave undefended), each active kit item *type* adds its `repelBonus` strength once. The chance is capped at `guardKit.repelCap` when there's 1+ active kit item, or `guardRepel.cap` otherwise. The roll uses up one unit of each active type (highest tier first), whether it works or not. A successful repel that used kit appends "They went through <items>." With 0 guards there's no roll and no spend. Faction repel is unchanged.

**Blocked by:** 01 — Guard kit core.

**Relevant files:** `systems/raiding.gd` (`guard_repel_chance` ~509, `guards_repel`, `_guards_repel_defend_raid` ~531, `_expire_pending_defend_raids`), `systems/guard_kit.gd`, `systems/home.gd` (`guard_repel_chance` mirror, which stays in step with any shared helper), `tests/test_raiding.gd`. Spec §Not defending. REFERENCE.md §3.12.

**Status:** ready-for-agent

- [ ] With a seeded Rng, the chance equals the base plus the sum of per-type strengths, capped at 0.90 with kit and 0.75 without.
- [ ] One unit of each active type is used on both success and failure, highest tier first. Inactive (over-capacity) units don't count and aren't used.
- [ ] 0 guards means no roll and no spend. The faction vein repel path is unchanged.
- [ ] Notification suffix flagged PROSE-REVIEW. REFERENCE §3.12 is updated.
