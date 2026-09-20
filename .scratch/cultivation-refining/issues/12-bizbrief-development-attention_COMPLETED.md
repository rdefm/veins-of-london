# 12 — BizBrief development-eligible & raid-risk attention item

**What to build:** BizBrief's Brief tab, attention section, surfaces owned veins currently eligible for development (per ticket 05's live eligibility check, including the terroir level cap — capped veins are never listed) along with their raised raid exposure (ticket 02's combined magnitude). No stale or impossible upgrade opportunities are shown.

**Blocked by:** 02, 05.

**Relevant files:**
- `scenes/phone_apps/bizbrief_app.gd` (Brief tab: bank, operations, attention)
- `systems/morning_accounts.gd` (rollover capture / BizBrief routing — check if this item needs snapshot integration or can be computed live)

**Status:** ready-for-agent

- [ ] Attention section lists owned veins currently eligible for development, derived from live eligibility state (not a stale snapshot)
- [ ] Veins already at their terroir level cap are never listed as development-eligible
- [ ] Each listed vein shows its raised raid exposure
- [ ] PROSE-REVIEW: any new BizBrief copy
