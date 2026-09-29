# 06 — Guards join the vein defend fight (no kit)

**What to build:** In a vein defend fight, the vein's guards fight as allies. After contacts are gathered, one "Hired Guard" ally per guard fills `combat.allies` up to `SQUAD_MAX` (3). A guard ally is a snapshot shaped like `Contacts.build_combat_ally` output, with stats from `guardKit.guardAlly`, a `guardAlly: true` marker and no `contactId`. Guards attack normally. A KO takes a guard out for the rest of the fight only: no walk, no cooldown, and `vein_guard_count` is unchanged afterwards.

**Blocked by:** 01 — Guard kit core (`guardAlly` JSON).

**Relevant files:** `systems/combat.gd` (`start_defend_vein` ~430, `_gather_defend_allies` ~444, `SQUAD_MAX`, `_ally_turn` ~1024, anything keyed on `ally["contactId"]` such as `_try_ally_rewind`/Dial lookups, which must skip guard allies), `systems/contacts.gd` (`build_combat_ally`), the combat screen's ally rendering, `tests/test_combat.gd`. Spec §Defend fight. REFERENCE.md §3.7.

**Status:** ready-for-agent

- [ ] Contacts join first, then guards fill the rest up to 3 in total. With 0 guards, the fight is the same as before.
- [ ] Guard allies take turns and attack. No code path dereferences a missing `contactId`.
- [ ] A KO'd guard is still counted by `vein_guard_count` after `exit_combat`.
- [ ] REFERENCE §3.7 is updated. On-device check: a fight with 3 guards and no contacts renders 3 allies.
