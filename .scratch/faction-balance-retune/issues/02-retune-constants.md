# 02 — Retune faction-balance constants

**What to build:** Using the harness from ticket 01, retune the existing
faction-balance constants — candidates: `Factions.RIVALRY_RELATION_PENALTY`,
`RIVALRY_RELATION_DIVISOR`/`RIVALRY_RELATION_WEIGHT`, `RIVALRY_BASE_CHANCE`,
`INDUSTRY_AGGRESSION` weights, `Sites.npc_claim_chance()`'s formula
constants, and `Sites.FACTION_PRUNE_BACK_TARGET` — until the harness shows
faction vein-share fluctuating without any faction trending to zero or to
dominance over a 100-150 day run. Keep all existing mechanic shapes
unchanged (rivalry odds formula, claim-rate formula, prune-back mechanic) —
this is a numeric-only retune, not a redesign; two prior numeric-only retune
passes on this exact problem are documented in `docs/adr/
0004-remove-npc-vein-abandonment.md`, so treat the harness's actual output
as the source of truth over intuition about which knob should matter most.

**Blocked by:** 01 (need the harness's baseline and re-run capability to
verify a retune actually holds).

**Status:** ready-for-agent

- [ ] Harness run against retuned constants, across multiple seeds, over
      100-150 simulated days.
- [ ] No faction's vein count trends to zero across any tested seed.
- [ ] No single faction trends toward owning the large majority of veins
      across any tested seed.
- [ ] Retuned constants and the rationale for each change are documented
      (commit message or ticket comment), flagged explicitly for human
      balance sign-off — same convention as other draft economy numbers in
      this codebase.
- [ ] Existing faction-balance tests (`tests/test_factions.gd` etc.) still
      pass unchanged in shape — only constants moved, not mechanics.
