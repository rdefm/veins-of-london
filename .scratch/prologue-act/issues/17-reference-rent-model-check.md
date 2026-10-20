# 17 — REFERENCE §1 / ADR 0006 rent-model check

**What to build:** `docs/story-restructure.md` notes that REFERENCE §1's property table and ADR 0006 still describe rent as `dailyCost`. Check them against the current bills model (Monday weekly home bill, tenure-aware, arrears, deposit) and correct the docs where they've drifted. Docs only; if code and docs disagree in a way that isn't clearly doc drift, stop and ask.

**Blocked by:** None — can start immediately.

**Relevant files:** `docs/REFERENCE.md` §1 (property table), §3.1, §3.3; `docs/adr/0006-property-bills-and-arrears.md`; `data/home.json` (`bills`); `systems/time_system.gd`, `systems/home.gd`.

**Status:** ready-for-agent

- [ ] No remaining `dailyCost` rent description that contradicts the code.
- [ ] ADR 0006 amended with a dated note if its model changed.
