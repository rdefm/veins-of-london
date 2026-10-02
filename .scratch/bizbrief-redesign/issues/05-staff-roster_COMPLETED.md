# 05 — Staff roster

**What to build:** Staff follows the selected roster layout: a live owed-wage summary, then compact cards for recruited contacts with role, pay terms, status, skills and available actions. Role selection, pay and the link to Manage → Procurement continue to work.

**Blocked by:** 01 — BizBrief app chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html` (Staff); `scenes/phone_apps/bizbrief_app.gd`; `systems/business.gd`; `systems/contacts.gd`; `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §2 contacts/business state, §3.10 Hiring, roles, wages and business pot; `CODEMAP.md` if ownership/files change.

- [ ] Staff still appears only after its current unlock; only recruited contacts are listed, with correct role, pay terms, unpaid/idle/working status, skills, XP and caps.
- [ ] Owed-wage summary derives from existing owed amounts; owed contacts retain affordable/disabled pay actions and founder contacts retain only currently available role choices.
- [ ] Role changes/clear, paying owed wages, and the Procurement link still invoke existing systems/navigation. Unrecruited and no-wage contacts remain accurate.
- [ ] Focused headless checks cover staff gates and actions; all tests pass. Report on-device checks for roster scanning and touch targets.
