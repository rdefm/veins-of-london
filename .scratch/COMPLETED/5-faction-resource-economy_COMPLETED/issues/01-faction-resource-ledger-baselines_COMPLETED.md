# 01 — Faction resource ledger + starting baselines

**What to build:** Each faction gains a real, persistent resource balance in `state.factions[id]` — a currency ledger (income in, spend out over time), not a value recalculated fresh from current holdings each tick. Factions start the game with **different baseline balances**, seeded to match their existing flavour text (Conclave and Guild read richer, Collective reads scrappier, per `data/factions.json`'s descriptions) — so factions are differentiated from turn one, not just once income/spend (later tickets) compound. This ticket only establishes the ledger and its baselines; nothing generates or spends from it yet.

The existing static `resourceLevel` field on `data/factions.json` (currently consulted as an explicit placeholder in `Factions._security_opulence()`, `systems/factions.gd`) stays in place for now — later tickets replace its use as a security-roll input with a read of this new dynamic balance. Whether the new baseline reuses `resourceLevel` directly (e.g. as a multiplier) or introduces its own distinct starting-baseline values is the implementer's call — document the choice in code. Note the current `resourceLevel` values (Collective 1, Firm/Network/Guild 2, Conclave 3) don't yet clearly read "Guild richer" per the PRD's framing; resolve this in whichever direction you choose for the baseline field.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `state.factions[id]` gains a new balance field (naming left to implementer, consistent with existing state-path conventions), initialised at game start to a per-faction baseline value that visibly differentiates factions per their flavour text.
- [ ] The balance is a plain numeric primitive (int or float) — no object references, Nodes, or Callables — so it survives `GameState.deep_copy()`, save/load, and Rewind snapshots without special-casing.
- [ ] No income or spend logic yet — the balance is static once seeded (that's tickets 02-04).
- [ ] Tests cover: each faction's starting balance matches its intended baseline tier, balances differ across factions as intended, balance round-trips through save/load and snapshot/restore unchanged.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
