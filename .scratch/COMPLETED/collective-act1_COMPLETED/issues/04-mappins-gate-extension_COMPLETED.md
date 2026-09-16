# 04 — MapPins gate extension

**What to build:** Let a map pin additionally require a minimum faction
relation and/or a minimum day, on top of the existing flag gates. Full detail
in `.scratch/collective-act1/spec.md` §5.4 — read it before starting.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `minRelation` and `minDay` are both optional keys on the `pin` block and
      default to no constraint.
- [ ] `minRelation` reads `state.factions[faction].relation`.
- [ ] Tests cover `minRelation` and `minDay` alone and combined with the
      existing flag gates (`_flags_satisfied`).
