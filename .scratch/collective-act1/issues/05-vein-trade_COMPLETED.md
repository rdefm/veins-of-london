# 05 — Vein sale (VeinTrade)

**What to build:** The first way to choose to stop owning a vein — quote a
sale price, confirm it, and transfer the vein to a faction in exchange for
cash. Full detail in `.scratch/collective-act1/spec.md` §5.6, §8.3 (worked
price table), §9.6 — read it before starting.

**Blocked by:** 02 (calls `Objectives.refresh()` at the end of a sale).

**Status:** ready-for-agent

- [ ] `quote(vein)` matches the §8.3 formula and worked examples exactly
      (`VEIN_SALE_BASE_UNITS = 35`, added to `data/vein_growth.json`).
- [ ] The price is shown and confirmed before the sale commits — no one-tap
      vein loss.
- [ ] `sell_to_faction()` removes the vein from `state.player.veins`, creates
      it as `site.factionVein` via `Factions.create_faction_vein()`,
      preserving `growth`, `oreType` and `hospitability`, and queues a
      `seed_claim` map event with the buying faction as owner.
- [ ] The transfer path supports a price of 0 (needed later by ticket 14's
      handback-to-Hakim, which is a transfer with no payment, same code path).
- [ ] The Sell option in `VeinList.actions_for()` is gated on
      `flags.veinSaleUnlocked` and, once that flag is set, applies to every
      vein permanently.
- [ ] `Objectives.refresh()` is called at the end of `sell_to_faction()`.
