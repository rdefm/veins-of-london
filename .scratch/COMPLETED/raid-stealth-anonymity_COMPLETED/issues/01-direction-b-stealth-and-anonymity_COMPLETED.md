# 01 — Direction B: stealth roll and identity concealment on faction vein raids

**What to build:** When a faction raids a player-owned vein (Direction B — `systems/raiding.gd`), a new stealth roll decides whether the attacking faction gets caught in the act. A **claim** (full takeover) is always attributed to the faction, unchanged — ownership visibly changing hands is inherently no secret, same logic Direction A already uses for its own claim branch. A **loot** (the vein stays player-owned, pruned + ore docked) is now gated by the new roll: caught still names the faction exactly as today; a clean loot anonymizes the notification instead. No relation change is applied either way — per the 2026-08-29 grill-me session, the player decides how (or whether) to react, this is not an automated stat hit.

**Confirmed mechanics (from 2026-08-29 grill-me session — no open design questions, only balance numbers to sign off):**

- **New stat:** each faction in `data/factions.json` gets a new stealth field (naming/exact value your call, e.g. `raidStealth`, camelCase per the existing `raidThreshold`/`conquerThreshold` convention) — a per-faction baseline, since the human explicitly chose "per-faction stealth stat" over a single flat constant or reusing the terroir table.
- **Roll:** faction's `raidStealth` vs. the target vein's `raidResist` (`Cultivating.vein_raid_resist()`, same field Direction A's own `resolve_stealth_check()` already reads) → success ("clean") or "caught". This is a **separate, independent roll** from the existing claim-vs-loot roll (`Raiding.claim_chance()` / `CLAIM_CHANCE_BY_TERROIR`) — that roll is unchanged and still decides claim vs. loot on its own. **Needs balance sign-off** on the exact formula/weighting, same as `CLAIM_CHANCE_BY_TERROIR` itself is flagged "draft only" — document the chosen shape in code.
- **Claim branch:** always reveals the faction's identity, regardless of the new roll's outcome — `resolve_raid_outcome()`'s existing claim notification (`"<Faction> raided your vein in <District>. It's theirs now."` and its missed-alarm variant) is untouched.
- **Loot branch:** caught → existing notification text, unchanged (`"<Faction> raided your vein in <District>, pruning it and getting away with <N> units of ore. It's still yours."` and its missed-alarm variant). Clean → same notification shape but with the faction's name replaced by an anonymous stand-in (exact copy is new prose — PROSE-REVIEW against CONTENT-GUIDE.md's tone bible; keep the distinct on-time vs. missed-alarm variants).
- **Alarm advance-warning:** `_queue_defend_raid()`'s pre-resolution warning (`"Alarm's gone off — %s are closing in on your vein in %s..."`) also gets anonymized when the eventual outcome will be a clean loot — since the stealth/caught roll happens at the same time as the existing claim/loot roll (`roll_raid_odds()` time), its result is already known and can ride through the queue exactly the way `outcomeType` already does. Claim-bound and caught-loot-bound warnings keep naming the faction as today.
- **No relation change:** neither branch calls `Factions.adjust_player_relation()` — confirmed explicitly, this is a deliberate divergence from Direction A's own claim/loot relation hits, not an oversight.
- **Combat is unaffected:** the alarm-defend fight itself (`Combat.start_defend_vein()`) already uses a generic guard-template enemy name (`generate_raid_enemy()`), never the faction's name, so no change is needed there to keep it consistent with an anonymized warning.
- **Direction A is out of scope:** its stealth check, claim/loot relation hits, and combat branching are already shipped (`7-vein-raiding` chunk) and stay exactly as they are.

**Where:** `data/factions.json` (new stat), `systems/raiding.gd` (`roll_raid_odds()`, `resolve_raid_outcome()`, `_apply_raid_loot()`, `_queue_defend_raid()`), `data/vein_security.json`/`Cultivating.vein_raid_resist()` (existing raidResist read, unchanged), `Notify.push` call sites for the affected notification text.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New per-faction stealth stat added to `data/factions.json` for all five factions, with a documented default and rationale in code.
- [ ] A new stealth/caught roll runs at the same time as the existing claim-vs-loot roll, independently of it, using the new stat vs. the target vein's `raidResist`; the outcome (caught/clean) rides through the pending-defend queue the same way `outcomeType` already does.
- [ ] Claim outcome notification (on-time and missed-alarm variants) is unchanged — always names the faction.
- [ ] Loot outcome, caught: notification unchanged — names the faction.
- [ ] Loot outcome, clean: notification anonymizes the faction's identity, both on-time and missed-alarm variants; new copy is PROSE-REVIEW flagged.
- [ ] Alarm advance-warning anonymizes the faction's identity when the queued outcome is a clean loot; keeps naming the faction when the queued outcome is a claim or a caught loot.
- [ ] Neither branch changes `state.factions[id].relation` — confirm no regression against Direction A's own (unchanged) relation-hit behaviour.
- [ ] Test coverage: stealth-roll success/caught distribution responds to the new stat and to `raidResist` in the right direction; claim notification always names the faction regardless of the stealth roll; loot notification names/anonymizes correctly per caught/clean; alarm warning anonymizes/names correctly per the queued outcome; relation is untouched in every Direction B branch.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
- [ ] Manual check noted for the human: trigger a few Direction B raids (or force the roll via debug) and confirm the notification text reads correctly across all four combinations (claim/loot × caught/clean), and that the alarm warning's identity-reveal matches its eventual outcome.
