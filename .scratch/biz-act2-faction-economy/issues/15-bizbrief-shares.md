# 15 — BizBrief: player shares

**What to build:** BizBrief shows the player's ore and crafting share per ore type with ▲/▼ versus last week, and supplier share per faction. Screen reads only.

Spec: §UI reads.

**Blocked by:** 04 — Shares core; 05 — Contract deliveries.

**Relevant files:**
- `scenes/phone_apps/bizbrief_app.gd`, `systems/shares.gd`, `price_move.gd` (▲/▼ idiom)
- Tests: bizbrief screen tests
- CODEMAP bizbrief_app row

**Status:** ready-for-agent

- [ ] Player ore/crafting share per type with week-on-week ▲/▼
- [ ] Supplier share per faction
- [ ] PROSE-REVIEW: labels
- [ ] Human on-device check listed in the report
