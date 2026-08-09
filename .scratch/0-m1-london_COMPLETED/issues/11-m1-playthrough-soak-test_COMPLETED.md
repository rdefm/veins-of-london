# 11 — M1 playthrough soak test

**What to build:** the extended seeded playthrough test proving all of M1's exit criteria end-to-end: prospect → seed → cultivate → harvest → sell across ≥3 districts, tutorial-gated, plus a 20-seed soak run.

**Blocked by:** 05, 09, 10.

**Status:** done (one item below needs a human — see Comments)

- [x] `tests/test_playthrough.gd` extended to cover the full M1 loop across ≥3 districts, seeded/deterministic
- [x] 20-seed soak run green, including NPC-claim/abandonment behaviour (no district permanently locks out prospecting) and event-deck draws firing without crashing
- [x] Confirms M1 exit criteria 1–5 from `docs/M1-LONDON.md` are met (see Comments for what's automatable vs. not)
- [ ] A human playtest session logged where a routing trade-off decision was reported unprompted (exit criterion 3) — **not agent-doable, needs a human**
- [x] `godot --headless --check-only --script` clean on all touched files (see Comments — verified via the full suite instead, this environment's check-only mode has a pre-existing limitation)

## Comments

Implementation notes (M1-LONDON-T08):

- `tests/test_playthrough.gd` gained: a shared `_play_through_tutorial_and_unlock_prospecting()` helper (extracted from the original run_case, now reused by all three new cases — drives the fixed tutorial beats through M1-LONDON D6's `archie_cultivation`, which is what actually flips `cultivationTutorialSeen`); `m1_loop_prospect_seed_cultivate_harvest_sell_across_three_districts` (the deterministic action chain across greenwich/camden/hampstead); `m1_20_seed_soak_no_permanent_district_lockout_and_event_draws_dont_crash` (20 explicit `Rng.set_seed()` runs proving siteCap/NPC-claim/NPC-abandonment per adr/0002 never permanently locks a district, plus a non-tautological `events_driven > 0` assertion that D5's district-deck draws actually fire and resolve); `district_event_driver_resolves_choice_cards_and_mid_event_combat` (deterministically forces `camden_shakedown`'s combat branch, since the soak only opportunistically hits it).
- Exit criteria 1–5 are covered at the systems level, matching every other test in this suite (none drive `scenes/screens/*.gd` — no scene-tree UI tests exist anywhere in this codebase; UI wiring is this project's documented human-visual-QA territory per the workflow rules in `CLAUDE.md`). Criterion 1's "entirely via the Map tab" is therefore proven for the underlying action chain and its data, not the Map tab's button wiring — which per D4's "screens... call system functions... not one line [of logic]" doctrine is a thin pass-through with no independent logic to test. Criterion 2 (block costs / labels) is already covered by `test_travel.gd`/`test_ui.gd`, not re-tested here. Criterion 3's visibility half (site quality visible pre-seed) is asserted directly; its human-report half is the one unchecked item above.
- Environment note: this machine's Windows Godot 4.4 build has a pre-existing limitation where `--headless --check-only --script <file>` fails to resolve autoload singletons (`Identifier not found: GameState`) — confirmed this reproduces identically on `main` before this change, on every test file, not something this ticket introduced. Verified correctness instead via the full suite (`godot --headless -s tests/test_runner.gd`): 369 passed, 0 failed, run clean across 8 consecutive full-process invocations (the same methodology `scripts/soak.sh` uses).
- Code review (standards + spec sub-agents): fixed a fragile `Sites.sites_in_district(district_id)[-1]` lookup (replaced with a proper reference-mutation holder pattern), added a local `_make_site()` fixture helper to match `test_sites.gd`/`test_district_events.gd`'s established convention (was inlining raw site dicts), and — the substantive one — added the `events_driven > 0` assertion and the dedicated combat-branch test, since the original soak only *opportunistically* exercised district-deck draws and mid-event combat with no assertion that either branch had ever actually fired.

**Outstanding, not agent-doable:** exit criterion 3's second half needs an actual human play session where a routing trade-off decision gets reported unprompted. Flagging for the human to run and log separately.
