# 03 — T5: Contested vein

**What to build:** The first Phase 1 choice — a named Collective vein taken by
the Firm, resolved by force or buyback. Full detail in
`.scratch/collective-act2/spec.md` §6.5 and §3.2 (the Firm's face) — read it
before starting.

**Blocked by:** 02 (Phase 0 must have activated Phase 1 pins/objectives).

**Status:** ready-for-agent

- [ ] `col_a2_contested_vein` event: setup names a Collective vein taken by
      the Firm since T3 (scripted or sim-driven loss, either acceptable per
      spec).
- [ ] **Force** branch calls `Raiding.claim_vein()` (existing relation-hit
      constant, no additional penalty).
- [ ] **Buy back** branch calls `VeinTrade.buy_from_faction(vein_id, "firm")`
      and introduces the Firm's face (§3.2) — unnamed, no Contacts card, no
      relation track, voice per §3.2's note (transactional, unbothered).
- [ ] `on_complete`: `state.methodLog.a2ContestedVein = "force" | "bought"`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_contested_vein.json`.
- [ ] `methodLog.a2ContestedVein` added to `GameState` schema.
- [ ] PROSE-REVIEW flag raised (Firm's face dialogue is draft per §3.2).
