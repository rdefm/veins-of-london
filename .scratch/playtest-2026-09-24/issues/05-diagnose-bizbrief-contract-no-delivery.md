# 05 — Diagnose: BizBrief contract never delivers or completes

**What to build:** Accepting a Sales contract in BizBrief, tapping to deliver everything, then letting days pass results in nothing delivered and the contract never completing. Diagnose (diagnosing-bugs loop), reproduce headless (no save file available), then fix so delivery happens and the contract settles.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/contracts.gd`, `systems/offers.gd`, `systems/morning_accounts.gd`, `systems/time_system.gd` (daily tick), `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/contract_card.gd`; `docs/biz-act1-vision.md` for intent.

**Status:** ready-for-agent

- [ ] Root cause written up under `## Comments`
- [ ] Headless test: accept → deliver all → advance days → goods delivered, contract settled, cash paid
- [ ] Covers enough-stock and short-stock cases
