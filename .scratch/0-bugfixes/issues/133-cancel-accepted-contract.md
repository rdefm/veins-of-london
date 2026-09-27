# 133 — Cancel an accepted contract

**What to build:** Each active contract in BizBrief gets a Cancel action. Tapping it opens a confirm pop-up (Confirm / Keep). Confirming ends the contract immediately, for one-off and recurring alike: it leaves the active list and priority order, goes into contract history as cancelled, and pays nothing more. Ore already delivered isn't refunded. No relationship hit for now — the counterparty and its relation hit are covered by `.scratch/biz-empire-act2/spec.md` stories 20a/20b. Cancelled contracts must not count toward any objective (contracts_completed, template_periods_completed, recurring_proof). Cancelling a quest-issued starter/recurring contract follows the same reissue rules as declining the offer (`starterReissueDay`, `recurringReissueDay`).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/contracts.gd`, `systems/business_quest.gd` (reissue rules), `systems/objectives.gd`, `systems/modal.gd`, `scenes/modals/`, `scenes/components/contract_card.gd`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_contracts.gd`; REFERENCE.md §3.10 "Business Empire questline" (starter/recurring reissue).

**Status:** ready-for-agent

- [ ] Cancelling removes the contract, records it as cancelled, pays nothing; tested for one-off + recurring
- [ ] Cancelled contracts aren't counted by objectives; tested
- [ ] Quest starter/recurring contracts get reissued after a cancel, same as a decline; tested
- [ ] Confirm pop-up; Keep leaves the contract untouched
- [ ] PROSE-REVIEW: pop-up copy
- [ ] Human on-device: cancel a contract, check the pop-up, check it's gone
