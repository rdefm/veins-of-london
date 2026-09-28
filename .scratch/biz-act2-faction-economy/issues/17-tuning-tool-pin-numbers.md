# 17 — 60-day tuning tool + pin numbers

**What to build:** A headless dev script (not a test) runs the daily rollover 60 days from a fresh start and prints per-good prices and per-producer shares. Use it to pin every placeholder in JSON and REFERENCE.md against the targets: each producer faction ~30–40% of its primary ore; Guild ~50%+ of crafting for its items; Independents ~20–25%; player at end of Act 1 ~10–15% of their main ore; idle London prices within sub-spec 1's feel targets.

Spec: §Tuning tool.

**Blocked by:** 10 — Per-vein kit allocation; 12 — Conclave arbitrage; 13 — Retire stand-in supply.

**Relevant files:**
- New script under `scripts/`, `data/factions.json`, `data/market.json`
- `.scratch/biz-act2-market-sim/spec.md` (price feel targets)
- REFERENCE.md §1.8, §3.13

**Status:** ready-for-agent

- [ ] Script runs headless and prints prices + shares
- [ ] Targets met (paste final run summary in report)
- [ ] All placeholders pinned in JSON and REFERENCE.md
- [ ] Full suite + check_all pass
