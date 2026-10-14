# 08 — One Morning report and Business money page

Status: ready-for-agent

**What to build:** Below Today, Brief gives one short Yesterday summary and direct links to the complete Morning report and Business money. Full accounts, payday, overnight operations and pot/float controls remain available without duplicated figures on the main Brief.

**Blocked by:** 01 — Compact BizBrief shell and Sales workstream; 05 — Focused Today hierarchy and exact action routes.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/morning_accounts.gd`, `systems/business.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §2 Screens and §3.10 Business pot and payday, Business float, `CODEMAP.md`.

- [ ] Yesterday summary uses the latest actual account and leads to full bank, payday, stock, production, sales, losses and exception detail.
- [ ] Business money shows pot and float separately, explains their existing roles, and preserves Donate/Withdraw limits and effects.
- [ ] Before the first account or before pot activation, both routes show accurate concise states; no sample figure or new accounting formula ships.
- [ ] Brief no longer repeats the same account/operations figures in multiple expandable sections. Focused Godot 4.7 tests pass; human checks the two detail pages on-device.
