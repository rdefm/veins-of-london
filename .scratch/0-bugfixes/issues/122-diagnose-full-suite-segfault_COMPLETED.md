# 122 — Diagnose intermittent full-suite segfault

**What to build:** Not a code fix — a written diagnosis. `scripts/run_tests.sh`
(`godot --headless -s tests/test_runner.gd`) intermittently crashes with a
native signal-11 segfault partway through the suite. Pin down the actual
mechanism (or establish that it's genuinely outside the codebase's control)
before anyone patches anything.

**Leading lead, not yet confirmed root cause:** project memory
(`project_full_suite_segfault.md`) already recorded, on 2026-09-15, that this
reproduces identically on a clean checkout with no changes applied
(`git stash`), and that the crash location moves between runs (seen at
`test_map_canvas.gd`, `test_map_controls.gd`, `test_messages.gd`,
`test_modal_layer.gd`) with no fixed file. Backtraces show no debug info
(release PE/COFF binary), so the trace alone hasn't been enough to diagnose
it. The suspicion on file is a headless-rendering/engine-state flake in this
sandboxed Windows environment (Godot 4.7 stable) rather than a logic bug in
any test or system file — confirm or refute this rather than assuming it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduces the segfault multiple times and records whether the crash
      location is truly random/file-independent, or clusters around a
      particular kind of test (off-tree screen tests, tests that build/free
      Control nodes, tests touching a specific autoload, etc.)
- [ ] Determines whether the crash is deterministic given a fixed RNG
      seed/run order, or genuinely non-deterministic run to run with
      identical inputs
- [ ] Checks whether the crash rate/location correlates with anything
      controllable from this repo: the ticket 116 `run_case()` teardown
      (queue_free/disconnect churn on off-tree nodes), Godot binary version
      (`.godot-bin/`), or headless rendering driver flags — vs. being a pure
      engine/sandbox issue unrelated to any code here
- [ ] Tries at least one isolation technique (e.g. running the suite in
      smaller shards/subsets via a filtered runner, or with verbose
      engine/driver logging) to narrow the mechanism further than "it moves
      around"
- [ ] Findings written up on this ticket (or a short doc referenced from it)
      with whatever reproduction steps were found, confirming or refuting the
      current engine-flake hypothesis
- [ ] Writes a new ticket (next number after this one, `ready-for-agent`)
      capturing the confirmed root cause and a proposed fix or mitigation
      approach (a real code fix if the cause turns out to be in this repo's
      control; otherwise a mitigation such as a filtered/sharded run mode
      that gives a trustworthy pass/fail signal without depending on the
      full single-process run surviving) — no fix is implemented in this
      ticket

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

## Findings (2026-09-16)

**Hypothesis refuted.** This is not a headless-rendering/engine-state flake
outside the codebase's control. It's a fully in-repo, deterministic-trigger
bug: `tests/test_base.gd`'s `run_case()` teardown (added in ticket 116)
`queue_free()`s the live `GameState` autoload singleton itself, the first
time any test file flushes a real engine frame. Every later `GameState.*`
access in the same process is then a use-after-free, which corrupts memory
and segfaults at a run-dependent later point — that's why the crash
location "moves around."

**Repro rate:** 3/3 full `run_tests.sh` runs on unmodified `HEAD` segfaulted
(not rare/intermittent in this environment — closer to 100%). Crash surfaced
at `test_map_screen.gd`, `test_sites.gd`, and (in a later isolation run)
`test_savemanager.gd`/`test_rooms.gd` — different file each time, confirming
the original memory's "moves around" observation, but see mechanism below
for why that's expected rather than mysterious.

**Determinism:** File discovery order (alphabetical) and in-file case order
are both fixed, so inputs are identical run to run. The crash's *surface
location* is nonetheless non-deterministic across runs with identical
inputs — consistent with memory-layout-dependent undefined behaviour from a
stale Object reference, not with a seeded-RNG-driven logic bug. No fixed
seed investigation was needed once the UAF mechanism below was confirmed.

**Godot binary version:** ruled out. `run_tests.sh` prefers
`PROJECT_DIR/godot`, which is genuinely Godot 4.7.stable
(`5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88`) — not the 4.4.1 winget install
that happens to shadow `godot` on PATH. Not a version-mismatch cause.

**Mechanism (confirmed via direct instrumentation):**

1. `autoload/GameState.gd::_ready()` runs
   `EventBus.shared_stock_increased.connect(_on_shared_stock_increased)`.
   Per ticket 123's already-filed (separate) finding, autoload `_ready()`
   callbacks are deferred under `godot --headless -s
   tests/test_runner.gd`'s synchronous `SceneTree` script and don't actually
   fire until the process flushes a real engine frame.
2. Most test files never flush a frame, so for most of the suite this
   connection simply doesn't exist yet on `EventBus`.
3. Five test files DO `await (Engine.get_main_loop() as
   SceneTree).process_frame` at least once: `test_hq_lab_bench.gd`,
   `test_map_canvas.gd`, `test_combat_screen.gd`,
   `test_phone_home_grid.gd`, `test_time_transition.gd`. Whichever of these
   runs first (`test_hq_lab_bench.gd`'s
   `hq_lab_bench_right_arrow_tweens_the_diorama_pan_when_in_a_live_tree`
   case, in file-discovery order) is also the first point `GameState`'s
   deferred `_ready()` actually executes.
4. `run_case()` snapshots `EventBus`'s connections *before* each case's
   `fn.call()` and disconnects+frees whatever's new *after*
   (`test_base.gd::_disconnect_and_free_new_eventbus_connections`, ticket
   116 — designed to catch leaked off-tree `Screen` nodes). Because
   `GameState`'s connection first appears mid-case here, it looks
   indistinguishable from a leaked node to that logic. `GameState extends
   Node`, so it passes the `target is Node` check.
5. Confirmed directly by temporarily instrumenting that function with a
   print of the freed target: `DIAG122: freeing target=GameState:<Node#...>
   sig=shared_stock_increased`. The live `GameState` autoload is
   `queue_free()`'d right there — not a copy, not a leaked screen, the
   actual singleton every system and screen reads/writes through.
6. Immediately visible in the very next case:
   `SCRIPT ERROR: Invalid access to property or key 'state' on a base
   object of type 'previously freed'` (at `systems/lab_bench_nav.gd:72`,
   reading `GameState.state`), then
   `SCRIPT ERROR: Invalid call. Nonexistent function 'reset' in base
   'previously freed'` (`GameState.reset()`). From here on `GameState` is a
   freed Node; every later access anywhere in the process is UB. Some hit
   GDScript's "previously freed" guard cleanly; others silently corrupt
   native memory and the process eventually segfaults somewhere unrelated —
   this is the actual mechanism behind "the crash location moves."

**Isolation experiments (each run 3x):**
- Excluding all 5 `await process_frame` files: **0/3 segfaults**, suite
  completes clean every time (2289 passed, 2 failed — same 2 pre-existing
  unrelated failures each run).
- `test_hq_lab_bench.gd` run alone (excluding the other 4): **3/3
  segfaults**, always triggered at the same case
  (`hq_lab_bench_right_arrow_tweens_the_diorama_pan_when_in_a_live_tree`),
  confirming a single file is sufficient to reproduce and pinpointing the
  exact trigger case.

**Relation to ticket 123:** this diagnosis independently confirms ticket
123's own leading hypothesis (GameState's `EventBus.shared_stock_increased`
connection is deferred and only becomes live once some test flushes a real
frame) — the two tickets describe the same timing hazard from different
angles (a silent no-op there vs. a freed autoload here).

- [x] Reproduces the segfault multiple times; crash location clusters
      around whichever test file the process happens to touch after
      `GameState` was freed — not truly random once the trigger is known
- [x] Crash is non-deterministic in *where* it surfaces despite identical
      run order/inputs (consistent with UAF, not a seeded logic bug)
- [x] Correlates with something fully controllable from this repo: ticket
      116's `run_case()` teardown, interacting with ticket 123's
      `GameState`/`EventBus` deferred-`_ready()` timing hazard. Ruled out
      Godot binary version mismatch.
- [x] Isolation via a filtered runner (excluding the 5 `process_frame`
      files, then narrowing to `test_hq_lab_bench.gd` alone) pinned the
      exact trigger case
- [x] Findings written up above
- [x] Follow-up ticket filed: `124-fix-run-case-frees-gamestate-autoload.md`
      (`ready-for-agent`)
