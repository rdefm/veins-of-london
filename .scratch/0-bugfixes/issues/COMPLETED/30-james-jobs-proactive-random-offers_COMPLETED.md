# 30 — James jobs become proactive random offers, remove player-request

**What to build:** Currently the player requests James jobs via "📋 Ask James for work" (`scenes/components/contact_cards.gd`) → `Jobs.offer_job()`. Remove the player-initiated ask. Instead, James randomly offers jobs (rolled on the daily tick, mirroring other `time_system.gd` daily rolls):
- **Type 1** (new): spend a time block, get paid a flat **£300**. Offer chance scales up to **100%** when `state.player.cash <= 100`; otherwise use a lower baseline chance (human to confirm the baseline if not specified — don't invent silently).
- **Type 2** (existing generation logic, `Jobs.generate_james_job()`): craft X of an item by Y days — add the missing **deadline** field (currently the job dict has no deadline at all; REFERENCE's shape is `{recipeKey, recipeName, symbol, qty, payPerItem, totalPay}` only).

Existing lifecycle (`Jobs.accept_job()/decline_job()/fulfil_job()`, `state.jamesJob`, `flags.jamesJobActive`, modals `james_job_offer`/`james_job_short`/`james_job_complete`) is reused/extended, not replaced.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] "Ask James for work" button removed from `contact_cards.gd`; `Jobs.offer_job()`'s manual-trigger path removed or repurposed for the new random roll.
- [ ] Daily tick rolls for a James job offer when none is active: type-1 (flat £300 for a time block) with chance scaling to 100% at `cash <= 100`, else a defined baseline chance; type-2 (existing craft-job generation) with the rest of the roll budget.
- [ ] Type-2 job dict gains a deadline (`byDay` or equivalent), and failing to fulfil by the deadline has a defined consequence (expire/cancel — confirm with human if not specified).
- [ ] `jobs`/`time_system` tests cover: type-1 chance scaling at low cash, type-2 deadline field present and enforced, no player-initiated job request path remains.
