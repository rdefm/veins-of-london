# 09 — T12: The handler meet

**What to build:** Nadia forces the sit-down; the Network handler introduces
Targets and Sourcing. Full detail in `.scratch/collective-act2/spec.md` §5.3,
§6.12, and §3.3 — read it before starting. The handler's contract (never
lies, everything sold true/fair/ruinous) is unchanged from the brainstorm;
this ticket only decides what concretely gets sold.

**Blocked by:** 08 (needs `colA2SecondLossSeen`).

**Status:** ready-for-agent

- [ ] `state.collective.networkIntel` schema added:
      `{ "<siteId>": { "expiresDay": int, "effect": "claim_bonus" | "security_freeze", "magnitude": float } }`.
- [ ] New effect op `network_reveal_vulnerable_vein`: player names an
      existing vein; handler always tells the truth — confirms genuinely soft
      (writes a timed `claim_bonus` entry, a flat addition to
      `Raiding.claim_chance()` / `Factions.rivalry_success_chance()` for that
      site, expiring after N days) or confirms it isn't (paid-for "no", no
      entry written). `security_freeze` variant: named site skipped by
      `Factions.apply_security_upgrades()` for N days.
- [ ] New effect op `network_reveal_site`: player names an ore type + minimum
      tier; reuses `Sites.roll_new_site()`/`Sites.roll_tier()` without
      duplicating their logic; delivered via a `pendingMessages` entry, not an
      instant reveal.
- [ ] Pricing (first pass, §7.2): anchor to `VeinTrade.quote()`'s ballpark for
      a vein of comparable tier/ore. Flag to the human that this is
      playtest-pending per §11.1 — do not treat as final.
- [ ] Every handler transaction nudges `state.factions.network.relation` by a
      small flat amount, same shape as `ARCHIE_SALE_RELATION_GAIN`.
- [ ] `col_a2_handler_meet` event per §6.12's beat outline. `on_complete`:
      `networkHandlerUnlocked true`; Targets and Sourcing action-bar entries
      unlocked wherever the handler's surface lives.
- [ ] Unit tests: `network_reveal_vulnerable_vein`'s timed entry expires
      correctly; `network_reveal_site` reuses `Sites.roll_new_site()`.
- [ ] Data validity: `state.factions.network` relation-accrual wiring reuses
      the existing per-faction `tradeProgress` pattern (no schema change
      beyond what already exists per faction).
- [ ] PROSE-REVIEW flag raised (handler's voice, §3.3).

**Manual QA (human, on-device):** the handler's action-bar surface itself
(not tested headless per spec §9).
