# 07 — Reynard's: daily spend/income graph tab

**What to build:** Reynard's bank app gets a second tab with a line chart of spend and income per day over the last 10 days (two series, shared scale, zero-filled days), alongside the existing ledger tab. Derived from the cash transaction log via a projection in the bank system (screens don't compute state).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/bank.gd`, `scenes/phone_apps/bank_app.gd`, `scenes/components/line_chart.gd`, `systems/business_stats.gd` (10-day zero-filled series pattern), `docs/ui-vision.md` (Reynard's brand chrome).

**Status:** ready-for-agent

- [ ] Pure projection func (day → spend, income) for last 10 days, tested
- [ ] Tab switch between ledger and graph
- [ ] Human check: graph readable, matches ledger totals
