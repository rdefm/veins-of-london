# 01 — Faction trade lane: generalize + Collective rates + Archie rescale

**What to build:** A generic per-faction trade lane so any faction can offer
buy/sell prices at a relation-narrowed spread, the way the Guild already does —
plus the Collective's own asymmetric spread (wide sell, modest buy) and
Archie's cut scaling with his relation instead of sitting flat at 0.5. Full
detail in `.scratch/collective-act1/spec.md` §5.5, §8.1, §8.2, §9.4 — read it
before starting.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Guild's buy/sell functions are generalized to take a faction id; a test
      asserts the Guild's actual prices are unchanged by the generalization.
- [ ] `data/faction_trade.json` holds both factions' lane config
      (anchorRelation, zeroRelation, spread bounds, memberOnly,
      applyDistrictPriceMod, mugRisk) per §9.4's table.
- [ ] Collective's sell spread runs 0.45→0.05 across relation 0→90 and its buy
      spread runs 0.15→0.05, decoupled from each other, anchored at relation 0
      (not `joinRelation`).
- [ ] No mugging risk and no district `priceMod` apply to the Collective lane.
- [ ] Archie's `PLAYER_CUT_RATIO` scales linearly 0.60→0.85 across relation
      10→80, flat outside that range; everything else about his lane
      (priceMod, `MUG_BASE_CHANCE`, mugging-pays-in-full-on-a-win) is
      unchanged.
- [ ] `docs/REFERENCE.md` R§3.6 is amended to describe the relation-scaled cut
      in place of the flat 0.5 (§13 amendment).

## Note

§14.1 flags that this ticket's economy changes and ticket 05's vein-sale
pricing push early income the same direction at once — sequence this ticket
before 05/06 (already reflected in the blocking edges below) and expect a
human playtest checkpoint before the numbers are called final.
