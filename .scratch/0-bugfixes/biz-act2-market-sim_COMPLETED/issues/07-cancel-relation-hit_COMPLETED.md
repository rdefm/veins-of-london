# 07 — Cancelling a contract hurts its counterparty

**What to build:** Cancelling an accepted contract applies a small flat relation loss (JSON) to that contract's counterparty via the existing player-relation adjuster. No other faction reacts — including no cross-faction hit for taking a Firm contract mid-Collective-questline. Spec §Contracts / Offers "Cancel", user stories 46–47.

**Blocked by:** 06 — Contract counterparty.

**Relevant files:**
- `systems/contracts.gd` (`cancel()`), existing player-relation adjuster (factions / relation accrual)
- `data/offers.json` (cancel relation hit)
- `scenes/phone_apps/bizbrief_app.gd` (cancel confirm may mention the hit — PROSE-REVIEW if so)
- `tests/test_contracts.gd`
- `docs/REFERENCE.md` §3.10 (cancel)

**Status:** ready-for-agent

- [ ] Cancel lowers relation with the counterparty by the JSON amount
- [ ] No other faction's relation changes
- [ ] REFERENCE.md §3.10 updated
