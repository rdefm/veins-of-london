# 02 — Soho and Hampstead sites

**What to build:** Soho becomes an unowned, contestable district with real sites leaning towards emotion and time ore, while keeping its marketplace role. Hampstead's site cap is raised so its control isn't decided by a trivial 2–0. Both districts get enough map stop slots to show their sites.

**Blocked by:** None — can start immediately

**Relevant files:** `data/districts.json` (soho, hampstead: `siteCap`, `oreBias`, `factionPresence`), `data/map_layout.json`, `systems/map_layout.gd`, `systems/sites.gd`, `docs/M1.5-NETWORK-MAP.md` (stop slots ≥ `siteCap × 2`), VISION §13 ("Soho: no veins" amendment), `tests/test_map_layout.gd`, site tests. REFERENCE.md district table.

**Status:** ready-for-agent

- [ ] Soho has a non-zero `siteCap` (TBD), an `oreBias` towards emotion and time, and an empty `factionPresence`; its marketplace behaviour is unchanged
- [ ] Hampstead `siteCap` raised (TBD, ~5–6)
- [ ] Map layout gives both districts ≥ `siteCap × 2` stop slots; layout tests pass
- [ ] Prospecting/NPC claims can produce sites in Soho
- [ ] VISION §13 amended; REFERENCE values marked TBD
