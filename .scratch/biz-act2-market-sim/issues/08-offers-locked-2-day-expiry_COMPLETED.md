# 08 — Offers price-locked at issue, expire after 2 days

**What to build:** An offer's price is taken from the London quote when the offer is issued and stays fixed; accepting freezes it onto the contract as `signedQuote`, and all settlement pays the signed price regardless of later reprices. Premium = existing multiplier stack (contract multiplier, mixed-type bonus, Sales-level bonus) on top of the quote; no haggling. **All** offers — random, scripted (incl. Act 1 `biz_starter_*` / `biz_recurring_*`) and renewal offers (09) — expire 2 days after issue: one JSON value replaces per-template `expiresAfterDays` and the random min–max roll. Act 1 beats must stay completable: scripted templates' existing reissue hooks cover a lapsed offer.

**Design change vs sub-spec:** replaces spec story 30 (pending price follows the market) and story 36's "few days" renewal expiry. Update `.scratch/biz-act2-market-sim/spec.md` (stories + Implementation Decisions) in this ticket.

**Blocked by:** 02 — Every lane reads the London price.

**Relevant files:**
- `systems/offers.gd` (`create_offer` ~line 94 expiry, `RANDOM_EXPIRY_*`, `quote_for_request`, `accept_offer`), `systems/contracts.gd` (settlement reads)
- `systems/business_quest.gd` (starter/recurring reissue — verify 2-day expiry doesn't softlock)
- `data/offers.json` (`expiresAfterDays` per template → one global value)
- `scenes/phone_apps/bizbrief_app.gd` (expiry display, if any)
- Tests: `tests/test_offers.gd`, `test_contracts.gd`, `test_business_quest.gd`
- `docs/REFERENCE.md` §3.10 (offer expiry, signed price)

**Status:** ready-for-agent

- [ ] Offer price unchanged by reprices while pending
- [ ] Accept stores `signedQuote`; settlement after further reprices pays the signed price
- [ ] Every offer type expires exactly 2 days after issue
- [ ] Act 1 questline tests still reach completion (lapsed scripted offers reissue)
- [ ] Sub-spec stories/decisions updated; REFERENCE.md §3.10 updated
