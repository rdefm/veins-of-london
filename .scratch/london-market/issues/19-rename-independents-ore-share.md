# 19 — Rename independentsOreShare to independentsOreSupplyMult

**What to build:** Rename the `independentsOreShare` config key to `independentsOreSupplyMult`. It is a supply multiplier on civilian ore demand (validated range 0-2, now 1.5), not a share. Pure rename: values, validator range and behaviour are unchanged. `independentsShare` (items) is out of scope.

**Blocked by:** 18.

**Relevant files:** `data/market.json`, `autoload/GameData.gd` (validator and comment near the market checks), `systems/market.gd` (`independents_supply` area, ~lines 39 and 65), `tests/test_market.gd`, `tests/test_phone_factions.gd`, `tests/test_shares.gd`, REFERENCE.md §3.13, CODEMAP.md if it names the key.

**Status:** ready-for-agent

- [ ] Old name appears nowhere in code, data, tests or REFERENCE.md (grep clean outside `_COMPLETED` tickets, `balance-report.md` history and `android/` build copies)
- [ ] Validator still enforces [0, 2] under the new name; a test pins that
- [ ] Market values and sim output unchanged (one 3-seed sim run, identical to before the rename)
- [ ] `scripts/check_all.sh` clean; full suite results same as before
