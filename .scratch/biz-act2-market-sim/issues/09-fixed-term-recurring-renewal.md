# 09 — Fixed-term recurring contracts + renewal offer

**What to build:** Recurring contracts run a fixed term then offer renewal. They gain `startDay`, `termWeeks` (default 4, JSON), `expiryDay` (a Monday). On the due-day tick where `dueDay ≥ expiryDay`, the final period settles as usual and the contract moves to history as expired instead of renewing, and a renewal offer is issued: same request lines and counterparty, `source: "renewal"`, priced at the quote on the day it's issued, 2-day expiry (per 08), bypasses `PENDING_CAP`. Accepting starts a new term. Declining or letting it expire costs no relation. Migration: an active recurring contract with no `expiryDay` gains one at its next weekly renewal (renewal day + 4 weeks); SaveManager leaves the field absent so this applies. One-off contracts keep their deadline model. Act 1 recurring templates must still complete the proof (2 qualified periods fit inside 4 weeks). Spec §Contracts / Offers "Term", "Renewal offer", "Migration".

**Blocked by:** 06 — Contract counterparty; 08 — Offers price-locked at issue.

**Relevant files:**
- `systems/contracts.gd` (`daily_tick` recurring renewal, history), `systems/offers.gd` (renewal offer creation, `PENDING_CAP` bypass)
- `systems/business_quest.gd` (Act 1 recurring flow)
- `data/offers.json` (`termWeeks`)
- `autoload/SaveManager.gd`
- `scenes/phone_apps/bizbrief_app.gd` (term/expiry on active card, renewal offer card)
- Tests: `tests/test_contracts.gd`, `test_offers.gd`, `test_business_quest.gd`, `test_savemanager.gd`, `test_time_system.gd`
- `docs/REFERENCE.md` §3.10 (term, renewal)

**Status:** ready-for-agent

- [ ] Rollover: contract reaching `expiryDay` settles its final period, lands in history as expired, renewal offer pending
- [ ] Renewal appears even with a full pending list; same lines + counterparty; fresh quote at issue
- [ ] Renewal expiry/decline: no relation change
- [ ] Old open-ended recurring contract gains `expiryDay` at next renewal
- [ ] One-off contracts unaffected; Act 1 proof still completes
- [ ] PROSE-REVIEW: renewal offer copy, term line on cards
- [ ] REFERENCE.md §3.10 updated
