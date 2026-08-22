# 02 — Objectives engine

**What to build:** Objectives as data — a small typed evaluator system that can
express "find this kind of ground," "trade this much with this faction,"
"sell a vein to this faction," and "grow this vein past a threshold," evaluated
explicitly at known action boundaries rather than on every state change. Full
detail in `.scratch/collective-act1/spec.md` §5.1 and §11 — read it before
starting. §9.2 gives the schema shape; the real Act 1 objective JSON entries
are authored by whichever thread ticket first needs them (08, 11, 12, 13), not
this one.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Exactly four evaluator types exist (`sites_discovered_matching`,
      `traded_with_faction`, `vein_sold_to_faction`, `vein_growth_above`), each
      tested against synthetic state per §12.2.
- [ ] `refresh()` is called explicitly (not via signal) at the five boundaries
      in §5.1, and is idempotent — calling it twice in a row produces the same
      result.
- [ ] `refresh()` sets `complete`/`completeFlag` only; it never awards
      relation, cash, or anything else.
- [ ] The Notes app renders a Collective section below the existing tutorial
      chain, showing each active objective's title/detail/done state live, and
      the section disappears when Act 1 completes. It's fine to ship this
      against a synthetic test objective if no real Act 1 objective exists yet
      at this point in the build sequence.
- [ ] Data validity: every objective id, param and referenced flag is checked
      by an extension to `GameData.validate()`.
