# 14 — Deadweight (raid loss cut)

**What to build:** Applied to HQ or a vein stockpile for N days, via the pattern decided in 12. Raid ore loss is cut by X% (brainstorm §3.4).

**Blocked by:** 12

**Relevant files:** `systems/home.gd`, `systems/raiding.gd`, `tests/test_raiding.gd`; REFERENCE §1.7 `data/home.json`, §3.12.

**Decision (12):** Entry points (ADR 0007): vein row/mini card as 13, plus an "Apply Deadweight" option in the HQ ore readout modal (hq_ore_readout_modal.gd); HQ's only placeable item, only cuts raid ore loss. Reuses 13's apply fn; refresh on reuse.

**Status:** ready-for-agent

- [ ] Raid loss is reduced by the tier's % while active, on the targeted place only
- [ ] Expiry stored as a day number (pure data)
