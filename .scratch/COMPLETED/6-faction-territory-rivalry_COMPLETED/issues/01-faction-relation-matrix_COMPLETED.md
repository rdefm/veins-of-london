# 01 — Faction-to-faction relation matrix (data + seed)

**What to build:** A new pure-data faction-to-faction relation matrix in `GameState.state` — distinct from the existing player-facing `state.factions[id].relation` stat, which this does not touch or read. Seed every pair of the 5 canonical factions (`collective`, `firm`, `guild`, `network`, `conclave`) with a baseline value (implementer's call — e.g. neutral-start or a bias reflecting existing `industries` overlap/rivalry flavour — document the seeding rationale in code, per the PRD's explicit open question on exact seed values). Add a small get/adjust API (e.g. `Factions.get_relation(a, b)` / `Factions.adjust_relation(a, b, delta)`) alongside the existing faction functions in `systems/factions.gd`. Values are plain numeric primitives only (int or float, plain Dictionaries) — no object references, Nodes, or Callables — so the matrix survives `GameState.deep_copy()`, save/load, and Rewind snapshots without special-casing. This ticket only establishes the matrix and its baseline; nothing reads or writes it yet (tickets 03/04 do).

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] New matrix structure added to `GameState.state`, covering every pair of the 5 canonical faction ids, seeded to documented baseline values
- [ ] Matrix values are plain numeric primitives only, so they round-trip through `GameState.deep_copy()`, save/load, and Rewind snapshot/restore unchanged
- [ ] A get/adjust API exists (naming left to implementer, consistent with existing `systems/factions.gd` conventions); the self-vs-self pair is either excluded or a documented no-op
- [ ] No daily-tick step reads or writes this matrix yet — that's tickets 03 and 04
- [ ] Tests cover: seed values present for every faction pair, get/adjust round-trip correctly, values survive save/load and snapshot/restore
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
