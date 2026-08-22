# 11 — Nadia meet (S8)

**What to build:** The introduction to Nadia and her standing-order problem,
which opens the trading objective. Full detail in
`.scratch/collective-act1/spec.md` §6.8 — read it before starting. Card text is
`PROSE-REVIEW:` draft.

**Blocked by:** 08, 07, 02.

**Status:** ready-for-agent

- [ ] `col_a1_nadia_meet` is reachable from Nadia's action bar from S4 onward.
- [ ] `on_complete` activates `col_a1_nadia_supply`
      (`traded_with_faction`: `oreType: "emotion"`, `qty: 30`,
      `minTransactions: 3`) and sets `colA1NadiaMet`.
- [ ] The objective completes regardless of which of the three Collective
      doors (Des/Nadia/Hakim) the qualifying trades are sold through.
