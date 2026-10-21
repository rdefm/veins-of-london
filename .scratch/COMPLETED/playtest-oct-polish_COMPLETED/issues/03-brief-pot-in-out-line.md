# 03 — Brief tab: daily pot in/out line

**What to build:** The player should see the business pot growing day to day, even though cash only reaches them on payday. Add one compact line to the BizBrief Brief tab: "Pot £X (+£in / −£out today)". Tapping it opens a 7-day chart of money in and out of the business (two series on a shared scale). The figures come from the existing BizBrief stats daily tally.

Avoid info overload: before adding, audit the existing Brief cards, rows and money/market pages. If something already shows the pot balance, merge into it or replace it rather than duplicate. Report what was merged or removed.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/business_stats.gd`, `systems/business.gd`, `systems/daily_brief.gd`, `data/daily_brief.json`, `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/line_chart.gd`. REFERENCE.md §3.10 "Business pot and payday"

**Status:** ready-for-agent

- [ ] Brief shows a single pot line with today's in/out (hidden or adapted when the pot isn't active)
- [ ] Tap opens a 7-day in/out chart
- [ ] No duplicate pot figure elsewhere on the Brief; merges listed in the report
- [ ] Projection logic is tested (system-level, no UI in tests)
- [ ] UI strings flagged PROSE-REVIEW
