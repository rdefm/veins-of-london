# 02 — Brief and Short Pay

**What to build:** Brief follows the selected layout: live closing balance and net change lead, urgent attention is easy to act on, treasury and operations follow. All existing account detail, payday, wage prompts, faction moves, war, London share, and supplier share remain accessible below in matching compact sections. Short Pay uses the same visual language and keeps its existing guard decision flow.

**Blocked by:** 01 — BizBrief app chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html` (Brief); `scenes/phone_apps/bizbrief_app.gd`; `scenes/phone_apps/short_pay_view.gd`; `systems/morning_accounts.gd`; `systems/business.gd`; `systems/guard_upkeep.gd`; `systems/shares.gd`; `systems/faction_ai.gd`; `tests/test_phone_bizbrief.gd`; `tests/test_guard_upkeep.gd`; `docs/REFERENCE.md` §1.6 Guard shortfall, §2 business/morning-account state, §3.1 daily tick, §3.10 Business pot and payday, §3.14 Shares; `CODEMAP.md` if ownership/files change.

- [ ] Hero, attention, treasury and operations use live state, show correct empty states, and retain all account/operations details through in-tab expansion or jump. Attention remains live before first rollover.
- [ ] Existing bank history, float donate/withdraw, wage prompt, alarm/message/development attention, and guard-shortfall routes still perform their current actions.
- [ ] Payday, exception details, faction moves, war/weariness, London share and supplier share remain visible and accurate in styled lower sections.
- [ ] Short Pay keeps current per-place guard choices, totals, deadline, confirmation and back/deep-link behaviour with BizBrief styling.
- [ ] Focused headless checks cover the data and actions above; all tests pass. Report on-device checks for urgent-item priority, long-page scrolling, and Short Pay controls.
