# 07 — Depletion: level loss and collapse

**What to build:** When a vein above level 1 reaches condition 0 (from drift or an action), it loses one level, resets condition to exactly 50, and clears its streak — it does not disappear or cascade through multiple levels, and no further drift applies that night once the reset happens. A level-1 vein at condition 0 keeps today's behavior unchanged: a 15% daily collapse chance that can delete it (site reverts to unclaimed for a player vein, deleted outright for a faction vein), rescuable by cultivating it back up before the roll lands against it.

**Blocked by:** 05 (shares the same per-vein nightly pipeline in `drift_veins()`; sequenced after eligibility/level-up to avoid conflicting edits to the same function).

**Relevant files:**
- `systems/cultivating.gd` (`drift_veins()` — depletion branch, existing 15%-collapse-at-level-1 logic)
- `docs/REFERENCE.md` §3.4 (left-wall/collapse description, once approved)

**Status:** ready-for-agent

- [ ] Level > 1 at condition 0: level -= 1, condition reset to exactly 50, streak cleared, no additional drift applied that night
- [ ] No cascading — a single depletion event loses exactly one level even if drift would otherwise push further
- [ ] Level 1 at condition 0 keeps the existing 15% daily collapse chance; a rescue via cultivation before the roll prevents it
- [ ] A replacement vein seeded after collapse starts fresh at level 1; the site keeps its terroir and level cap
- [ ] Test: depletion above level 1 loses one level and resets to 50 without disappearing or cascading
- [ ] Test: level 1 at 0 retains the 15% collapse roll and can be rescued by cultivating before it lands
