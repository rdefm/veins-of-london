# 10 — T13: Hakim's vein retaken

**What to build:** Getting the yard back — force or buy, using bought intel —
and the ground itself does not come back either way. Full detail in
`.scratch/collective-act2/spec.md` §5.4 and §6.13 — read it before starting.
§11.3 item 4: no dialogue should explain the site is permanently gone; the
site reading as empty is the whole statement.

**Blocked by:** 09 (enabled once the player has bought at least one piece of
Targets intel on the Firm-held site from T10).

**Status:** ready-for-agent

- [ ] New one-off effect op `col_a2_ruin_site`: sets a single narrow flag
      (e.g. `site.ruinedByFirm = true`) on the site formerly at
      `state.collective.hakimVeinId`. `Sites.attempt_seed()` gains a two-line
      guard rejecting that one flag. No new tier, no new field on the general
      vein/site schema beyond this one boolean; nothing else in the codebase
      ever sets it. Whether the site becomes inert claimed-but-unseedable or
      is removed from `state.world.sites` is an implementation choice.
- [ ] `col_a2_hakim_retake` event, two branches:
  - [ ] **Force** → `Raiding.claim_vein()`.
  - [ ] **Buy** → `VeinTrade.buy_from_faction(vein_id, "firm")` — the Firm's
        face reappears, unmoved.
- [ ] Either branch fires `col_a2_ruin_site` immediately after the ownership
      transfer completes.
- [ ] `on_complete`: relation `+15`; `colA2HakimRetaken true`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_hakim_retake.json`.
- [ ] Unit tests: `Sites.attempt_seed()` rejects the flagged site and no
      other; grep-based data-validity test confirming the `ruinedByFirm` flag
      is set by nothing else anywhere in the codebase.
- [ ] `methodLog`/flag additions: `colA2HakimRetaken` added to `GameState` schema.
- [ ] PROSE-REVIEW flag raised — Hakim's reaction cards specifically.
