# 15 — BizBrief: player shares

**What to build:** BizBrief shows the player's ore and crafting share per ore type with ▲/▼ versus last week, and supplier share per faction. Screen reads only.

Spec: §UI reads.

**Blocked by:** 04 — Shares core; 05 — Contract deliveries.

**Relevant files:**
- `scenes/phone_apps/bizbrief_app.gd`, `systems/shares.gd`, `price_move.gd` (▲/▼ idiom)
- Tests: bizbrief screen tests
- CODEMAP bizbrief_app row

**Supplier share decision (2026-09-28, human):** record and show BOTH reads, per faction, over the 7-day window:
- **A — delivery split:** player deliveries to faction F ÷ all player contract deliveries ("where my output goes").
- **B — intake share:** player deliveries to F ÷ F's total intake (player deliveries + F's London buys) ("how dependent F is on me"). Needs a per-faction London-buy tally in Shares, recorded by ticket 11's buying.
- Unit for both: ore-equivalent (calc 1:1; items count recipe ingredient weights).
Ticket 04 stores only the delivery tally (`Shares.record_delivery`); the reads land in 05, the buy tally in 11, display in 15.

**Status:** ready-for-agent

- [ ] Player ore/crafting share per type with week-on-week ▲/▼
- [ ] Supplier share per faction
- [ ] PROSE-REVIEW: labels
- [ ] Human on-device check listed in the report
