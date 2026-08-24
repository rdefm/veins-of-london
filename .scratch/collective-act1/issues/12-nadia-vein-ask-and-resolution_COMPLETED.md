# 12 — Nadia vein ask + sale resolution (S9–S10)

**What to build:** Nadia proposing the player seed and sell her a vein instead
of endlessly supplying loose ore, and the scene that fires automatically the
moment that sale completes. Full detail in `.scratch/collective-act1/spec.md`
§6.9, §6.10 — read it before starting. Card text is `PROSE-REVIEW:` draft;
card 5 of S9 is the in-fiction explanation of the vein-sale growth factor.

**Blocked by:** 11, 05, 02.

**Status:** ready-for-agent

- [ ] `col_a1_nadia_vein` (S9) is enabled by `colA1NadiaSupplied`; `on_complete`
      activates `col_a1_nadia_vein` objective (`vein_sold_to_faction`:
      `factionId: "collective"`, `oreType: "emotion"`), sets
      `flags.veinSaleUnlocked true` (permanently, for every vein — this is the
      moment the Sell option in `VeinList` first appears) and
      `colA1NadiaAskSeen`.
- [ ] `col_a1_nadia_done` (S10) fires automatically from
      `VeinTrade.sell_to_faction()` completing the qualifying sale, not from
      the action bar; `on_complete` awards +8 collective relation and sets
      `colA1NadiaThreadDone`.
