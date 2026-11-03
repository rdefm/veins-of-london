# 17 — Landmark deals ladder (Archie) + supplier-contract spine beat

**What to build:** Archie's **Landmark deals** ladder: reaching a rung unlocks a specific, authored, recurring contract (buyer, volume, pay, term per rung), so the count of high-paying recurring contracts is controlled. Also Act 2 spine beat 2, **pinned** once beat 1 is done: sign a 4-week supplier contract with a faction that crafts with the player's chosen ore. Landmark balance (count, pay, term) authored here as placeholders.

**Blocked by:** 06 — Market share ladder (Archie) + pinned Act 2 share beat; slice 1 (01–14) playtested and tuned

**Relevant files:**
- `systems/contracts.gd`, `systems/offers.gd`, `data/offers.json`, `data/faction_trade.json`
- `systems/objectives.gd` (contract-signed condition), `systems/board_meetings.gd`, `data/board.json`
- `systems/todo.gd` (spine item)
- `tests/test_board_meetings.gd`, contracts tests
- Spec: stories 53–54, 62–64, §"Act 2 spine rules"

**Status:** needs-triage

- [ ] Rung reward unlocks its authored recurring contract
- [ ] Beat 2 pinned only after beat 1 done; passable; completes spine beat 2
- [ ] Balance in data; REFERENCE.md updated
