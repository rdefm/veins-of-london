# 07 — Contact roster + recruit suppression + trade doors

**What to build:** Des, Nadia and Hakim exist as real contacts with a
suppressed recruit row, and each offers the Collective trade lane through
their action bar on identical terms. Full detail in
`.scratch/collective-act1/spec.md` §3 (cast), §7.1, §7.2 — read it before
starting. Story-specific action-bar entries (e.g. "Tell Des about the ground")
are each thread ticket's own job; this ticket only wires the Trade row.

**Blocked by:** 01 (the lane Trade routes to), 03 (the action bar it lives in).

**Status:** ready-for-agent

- [ ] `des`, `nadia`, `hakim` exist in `data/constants.json` with
      `startRelation: 0`, `unlocked: false`, `recruitable: false`,
      `recruitThreshold: 0`; `archie` and `james` get `recruitable: true`
      added.
- [ ] The recruit row is not shown at all (not shown-disabled) when a
      contact's `recruitable` is false.
- [ ] Each of the three offers Trade in their action bar at identical terms
      and identical relation award — differing only in a per-vendor bark line
      drawn on completing a trade (`data/collective_barks.json`, minimum 6
      lines each, no-repeat-until-exhausted via `state.collective.barkCursors`).
- [ ] `docs/VISION.md` §14 amended for the three-new-contact budget deviation
      from "+1–2 new contacts by 1.0" (§13 amendment), and
      `plans/COLLECTIVE-QUESTLINE.md` §9 open question 6 (which contacts get
      relation tracks) marked closed by spec.md §3/§8.4.
