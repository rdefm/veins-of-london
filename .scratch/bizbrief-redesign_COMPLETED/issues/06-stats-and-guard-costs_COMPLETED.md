# 06 — Stats and Guard Costs

**What to build:** Stats follows the selected performance dashboard with live revenue/expense figures, daily trend, expense analysis, ore-source toggle and item production. Guard Costs opens from the guard expense entry as a matching BizBrief view, retaining its bill, shortfall and place-filter controls.

**Blocked by:** 01 — BizBrief app chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html` (Stats); `scenes/phone_apps/bizbrief_app.gd`; `scenes/phone_apps/guard_costs_view.gd`; `scenes/components/line_chart.gd`; `systems/business_stats.gd`; `systems/guard_upkeep.gd`; `tests/test_phone_bizbrief.gd`; `tests/test_guard_upkeep.gd`; `docs/REFERENCE.md` §2 businessStats state, §3.10 Business stats, §1.6 Monday guard bill/shortfall; `CODEMAP.md` if ownership/files change.

- [ ] Stats remains gated by the active business pot. Hero figures and charts derive from the existing 10-day completed-day series, including zero-filled days; no sample values are hardcoded.
- [ ] Revenue, expenses, staff/guard/calc expense breakdown, cultivator/player ore toggle, and items produced remain available and legible in the new hierarchy.
- [ ] Guard expense opens matching Guard Costs; next Monday bill, pending shortfall, historical payments, HQ/vein filters, Short Pay route and back navigation still work before or after pot activation.
- [ ] Focused headless checks cover series, toggle, guard route and filters; all tests pass. Report on-device checks for chart contrast, legends, filters and scrolling.
