# 12 — Austerity raises weekly living costs by 5%

**What to build:** When Austerity is the active political barometer state, the next Monday living-cost bill is 5% higher than its base before other active barometer modifiers. Replace the current 15% reduction. Keep the existing weekly billing and effect-merging rules.

**Blocked by:** None — can start immediately. Blocks 05 — Full state and London Wire articles.

**Status:** ready-for-agent

**Relevant files:** `docs/REFERENCE.md` §1.9 `data/barometer.json`, §3.2 Barometer, §3.1 daily tick order; `data/barometer.json`; `systems/barometer.gd`; `systems/time_system.gd`; `scenes/phone_apps/ticker_app.gd`; `tests/test_barometer.gd`; `tests/test_time_system.gd`; `.scratch/ticker-revamp/ticker-state-prose-draft.md`; `CODEMAP.md`.

- [x] Canonical rules and state data specify Austerity `dailyCost: +0.05`; its other effects remain as specified unless the human separately changes them.
- [x] The existing Monday bill calculation applies the merged +5% Austerity modifier for rented and owned homes; tests cover the bill and its combination with another active living-cost modifier.
- [x] Austerity's state description, headlines, Ticker impact display, and approved article prose agree with the new increase; no player-facing copy claims that Austerity lowers living costs.
- [x] Godot 4.7 syntax checks and the full headless test suite pass. The report identifies on-device Ticker and Monday-bill checks.
