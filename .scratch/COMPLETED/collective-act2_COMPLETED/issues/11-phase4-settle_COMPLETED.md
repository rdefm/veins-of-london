# 11 — Phase 4: Settle (T14-T15)

**What to build:** The arc's close — a silent spine-reward extension to
Hakim's intel roll, then the ledger read as relief, Des's one unease beat
surfacing and dropping. Full detail in `.scratch/collective-act2/spec.md`
§5.6, §6.14, §6.15, and §7.4 (the gate condition) — read it before starting.

**Blocked by:** 03 (T5), 04 (T6), 05 (T7), 10 (T13) — all four are read by the
§7.4 gate condition.

**Status:** ready-for-agent

- [ ] T14 fires automatically once `methodLog.a2ContestedVein`,
      `a2VulnerableSite`, `a2HostileMember` are all set, AND
      `colA2HakimRetaken` is true, AND `state.factions.collective.relation >= 50`.
      One short Hakim text (§6.14's PROSE-REVIEW line) plus extending
      `Collective.maybe_trigger_hakim_intel()`'s roll (§5.6): past this
      point, the roll may instead flag an existing enemy-held vein reading
      unusually weak, alongside its existing unclaimed-site behavior.
- [ ] `col_a2_closer` (T15) per §6.15's beat outline — Nadia's warmth, Des's
      one brief unease beat (not returned to), the understated resolution
      line. `on_complete`: `colA2Complete true`.
- [ ] Event id added to `GameData.EVENT_IDS`; `data/events/col_a2_closer.json`.
- [ ] `colA2Complete` flag added to `GameState` schema.
- [ ] PROSE-REVIEW flag raised on both, especially T15's resolution line and
      Des's dropped-unease beat (§11.3).
