# 03 — Manage sales pipeline

**What to build:** Manage opens with the selected sales-pipeline summary, then separate offered and accepted contract cards. Players can review the same terms, accept/match/decline offers, drag delivery priority, toggle buy-missing-calc, inspect history, and cancel with a BizBrief-styled confirmation. Mockup links reveal existing details within Manage.

**Blocked by:** 01 — BizBrief app chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html` (Manage); `scenes/phone_apps/bizbrief_app.gd`; `scenes/components/contract_card.gd`; `scenes/modals/contract_cancel_modal.gd`; `systems/offers.gd`; `systems/contracts.gd`; `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §2 sales state, §3.10 Offer price and expiry, Counterparty, Contract delivery/settlement/cancellation; `CODEMAP.md` if ownership/files change.

- [ ] Pipeline counts, offer status/expiry/payment, active progress/due date, and history all derive from current state; no mockup sample values or invented sales rules.
- [ ] Renewal and poached offers still expose the correct terms and Accept/Match/Decline actions; empty and gated states remain clear.
- [ ] Accepted cards retain delivery-priority drag, buy-calc toggle, recurring-period/term information, sales-staff status, and cancellation. Details/History links reveal the existing information in-tab.
- [ ] Cancel confirmation matches BizBrief's aesthetic and still invokes the existing confirm/keep flow.
- [ ] Focused headless checks cover offer and contract actions, priority and history; all tests pass. Report on-device checks for card density, drag/tap targets, and cancellation.
