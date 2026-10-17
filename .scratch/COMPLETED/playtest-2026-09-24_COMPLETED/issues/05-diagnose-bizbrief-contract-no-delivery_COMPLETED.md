# 05 — Diagnose: BizBrief contract never delivers or completes

**What to build:** Accepting a Sales contract in BizBrief, tapping to deliver everything, then letting days pass results in nothing delivered and the contract never completing. Diagnose (diagnosing-bugs loop), reproduce headless (no save file available), then fix so delivery happens and the contract settles.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/contracts.gd`, `systems/offers.gd`, `systems/morning_accounts.gd`, `systems/time_system.gd` (daily tick), `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/contract_card.gd`; `docs/biz-act1-vision.md` for intent.

**Status:** ready-for-agent

- [ ] Root cause written up under `## Comments`
- [ ] Headless test: accept → deliver all → advance days → goods delivered, contract settled, cash paid
- [ ] Covers enough-stock and short-stock cases

## Comments

2026-09-25: No code defect reproduced headless. UI-driven accept → Deliver all → rest: enough stock delivers + settles complete + pays; short stock delivers partial, settles partial at due day. Only "nothing delivered" paths: Deliver all tapped with 0 shared stock (silent `No shared stock available.`, one-shot, not standing), or delegated with no staffed/paid Sales — both settle £0 partial at due day. Human confirmed issue already fixed; closed without code change.
