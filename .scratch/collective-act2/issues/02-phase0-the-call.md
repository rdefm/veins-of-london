# 02 — Phase 0: The Call (T1-T4)

**What to build:** Act 2's mandatory linear opener — Des's urgent text, the
shop aftermath, the pattern hub, and Nadia's handler pitch deferred. Full
detail in `.scratch/collective-act2/spec.md` §6.1-§6.4 — read it before
starting, including the tone notes (urgency without melodrama at T1,
"administrative not operatic" at T2, Des's caution stated as caution not
doctrine at T4).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `col_a2_intro` (T1): Des text via `pendingMessages`, gated on Act 2's
      open condition (`colA1Complete AND state.factions.collective.relation >= 25`).
- [ ] `col_a2_shop` (T2): the shop scene per §6.2's beat outline;
      `on_complete` sets `colA2ShopSeen`.
- [ ] `col_a2_pattern` (T3): the hub scene per §6.3; `on_complete` activates
      the Phase 1 objectives/pins for T5-T7 (tickets 03-05) and sets
      `colA2Stage "call"`.
- [ ] `col_a2_handler_deferred` (T4): Nadia/Des exchange per §6.4;
      `on_complete` sets `colA2HandlerDeferred true`.
- [ ] All four event ids added to `GameData.EVENT_IDS` and their JSON files
      under `data/events/col_a2_{intro,shop,pattern,handler_deferred}.json`.
- [ ] New flags (`colA2Stage`, `colA2ShopSeen`, `colA2HandlerDeferred`) added
      to `GameState`'s schema.
- [ ] PROSE-REVIEW flag raised on all four event files (spec §3.2/§6 marks
      all new prose as draft).

**Manual QA (human, on-device):** confirm T1's text arrives correctly gated;
confirm the T3 hub actually unlocks T5-T7's map pins/action-bar entries.
