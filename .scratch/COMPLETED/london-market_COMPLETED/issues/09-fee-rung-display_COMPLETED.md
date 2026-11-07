# 09 — Fee rung display

**What to build:** The Soho trade screen makes the fee ladder obvious. It shows every rung with the player's position, and updates as quantity moves up or down. It says in plain terms how much more reaches the next rung and what that rung's % is. Crossing a rung gives a clear signal. The top rung shows that the best rate is reached. A comparison shows Soho against Archie for the current order.

Rung edges: an order just past a buy rung can cost less than one just below it. This is accepted, and the screen can use it as a prompt.

Spec: `.scratch/london-market/spec.md`, "Trading screen", "Further Notes". Stories 62-70.

**Blocked by:** 08

**Relevant files:** `scenes/modals/sell_menu_view.gd`, `systems/soho.gd`, `tests/test_soho.gd`, `docs/ui-vision.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] % fee, £ fee and net result update live as quantity moves both ways
- [ ] All rungs show at a glance, with the current position marked
- [ ] Next rung shows its threshold, its rate, and the £ and units still needed
- [ ] Crossing a rung up or down is clearly signalled
- [ ] The top rung shows the best rate reached and no next-rung prompt
- [ ] Soho vs Archie shows for the current order
- [ ] Every number comes from the fee rows, and those rows are tested
- [ ] Layout follows `docs/ui-vision.md`; on-device checks are listed for the human
