# 14 — Hakim thread resolution (S12)

**What to build:** Handing the recovered vein back to Hakim — which means
transferring it to the Collective, not to the player — and unlocking his
unprompted intel. Full detail in `.scratch/collective-act1/spec.md` §6.12 —
read it before starting. Card text is `PROSE-REVIEW:` draft.

**Blocked by:** 13, 05.

**Status:** ready-for-agent

- [ ] `col_a1_hakim_done` is enabled on Hakim's action bar by
      `colA1HakimRescued`.
- [ ] `on_complete` transfers the vein to the Collective at price 0 via the
      `VeinTrade` transfer path (same code path as a normal sale, price
      argument 0 — no separate mechanism), adds £120 cash, awards +8
      collective relation, sets `colA1HakimThreadDone` and
      `hakimIntelUnlocked`.
