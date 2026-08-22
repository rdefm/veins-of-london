# 45 — Archie raid-assist (relation ≥50)

**What to build:** Building on ticket 44's ally-combat engine: at `contacts.archie.relation >= 50`, the player can ask Archie to help raid another faction's vein, not just defend their own. This reuses 44's ally-combat mechanics (second attacker, own consumables, KO-able) in the raid-attempt context instead of the defend context.

**Blocked by:** 44 — Archie as combat ally (vein defense).

**Status:** ready-for-agent

- [ ] Raid-initiation UI/flow gains an option to bring Archie along, visible/enabled only when `contacts.archie.relation >= 50` and Archie is recruited.
- [ ] When brought along, Archie participates in the resulting raid combat exactly as in ticket 44 (second attacker, own consumables, KO-able).
- [ ] Relation threshold constant (`50`) added alongside other contact thresholds (e.g. `recruitThreshold`) rather than hardcoded inline.
- [ ] `docs/REFERENCE.md` updated with the raid-assist relation threshold.
- [ ] New test confirming the raid-assist option is gated correctly by relation and recruitment status.
- [ ] Manual check noted for the human: raise Archie's relation to ≥50, confirm the raid-assist option appears, and confirm a raid attempt with him along plays out correctly.
