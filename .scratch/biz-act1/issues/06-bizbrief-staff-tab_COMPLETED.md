# 06 — BizBrief Staff tab

**What to build:** A third BizBrief tab listing every recruited contact: role, skill levels, XP, caps, pay terms ("⅓ share" / "£250 a week" / daily wage) and working/unpaid status. It holds the role-assignment control (respecting role availability), the Pay now action while Owen is owed, and a link to Manage → Procurement for vein picking. Visible once the Beat 3 flag is set. It holds no roster state of its own.

**Blocked by:** 01 — Founder roles, skill caps, Owen roster, save fix-ups; 03 — Per-block staff step; 04 — Business pot and payday

**Relevant files:** `scenes/bizbrief_app.gd`, `systems/contacts.gd` (role assignment API), `systems/business.gd` (pay-now, unpaid status), `systems/payroll.gd` (daily wage display), `tests/test_phone_bizbrief.gd`; `docs/ui-vision.md`; spec §"BizBrief", User Stories 77–80.

**Status:** ready-for-agent

- [ ] Staff tab appears only when the Beat 3 flag is set (test can set flag directly)
- [ ] Lists every recruited contact from contacts state with role, skills, XP, caps, pay terms, working/unpaid
- [ ] Role control calls the contacts system; offers only roles the contact currently has available
- [ ] Pay now shown only while Owen is owed; calls Business pay-now
- [ ] Link navigates to Manage → Procurement
- [ ] Screen reads state and calls systems only (test pattern of `test_phone_bizbrief.gd`)
- [ ] New UI strings flagged `PROSE-REVIEW:`; CODEMAP.md updated; on-device QA block in report
