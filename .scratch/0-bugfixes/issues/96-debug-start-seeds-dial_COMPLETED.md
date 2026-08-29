# 96 — Debug Start grants a seeded Dial

**What to build:** `DebugStart.apply()` already hands the player maxed skills, three pre-grown veins, recruited contacts, and a full item roster — no RNG, no grinding, everything ready to test immediately. The Dial (`player.dial`) is the one major system it skips: today a debug-started game still has `dialGiftGranted` forced true by the flag-forcing pass, but seeding the Dial itself still goes through the gift-gated UI, its real calc cost, and a 30% success roll — and that cost (`data/dial.json`'s `seedCost`, 80 `life`) exceeds the flat 50-per-ore-type debug start currently grants, so the roll can't even be attempted without first grinding more calc.

**Confirmed mechanics (from 2026-08-29 grill-me session — no open design questions):**

- Debug Start should directly grant an already-seeded Dial, bypassing the gift-flag check, calc cost, and success roll entirely — same "no grinding" treatment as everything else in this file.
- **Bare, not kitted:** explicitly confirmed "just seed it, bare" — no Movement seated, no Complications loaded. The player still exercises the Craft Movement / seat / load-Complication UI themselves from a debug start; only the seeding step itself is skipped.
- This is additive to `DebugStart.apply()` only — `Dial.attempt_seed()` and the real gift-gate/cost/roll flow are untouched for normal play.

**Where:** `systems/debug_start.gd` (`DebugStart.apply()`), `systems/dial.gd` (`_new_dial()` — reuse its exact inert-Dial shape rather than hand-building a duplicate dict), `data/dial.json` (haft ids, for picking one to seed with).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `DebugStart.apply()` sets `player["dial"]` to a fresh, inert, level-1 Dial (matching `Dial._new_dial()`'s exact shape) with a valid haft id, no Movement seated, no Complications loaded.
- [ ] Normal play's `Dial.attempt_seed()` gift-gate/cost/roll behaviour is completely unchanged.
- [ ] Test coverage: a debug-started game has a non-null `player.dial` with the expected inert shape (level 1, no movement, no loaded complications, valid haftId).
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes.
- [ ] Manual check noted for the human: debug-start a game and confirm HQ → Practice shows a seeded Level 1 Dial immediately, with the Craft Movement section available to use from there.
