# 124 — Fix `run_case()` freeing the live `GameState` autoload

**What to build:** A real code fix (not diagnosis-only). Ticket 122 confirmed
`scripts/run_tests.sh`'s intermittent segfault is caused by
`tests/test_base.gd::run_case()`'s ticket-116 teardown
(`_disconnect_and_free_new_eventbus_connections`) `queue_free()`-ing the
live `GameState` autoload singleton the first time any test flushes a real
engine frame (the `hq_lab_bench_right_arrow_tweens_the_diorama_pan_when_in_a_live_tree`
case in `tests/test_hq_lab_bench.gd` is the earliest trigger, in
file-discovery order). Every later `GameState.*` access in the same process
is then a use-after-free, which eventually segfaults somewhere unrelated.
Full mechanism, repro steps, and isolation experiments are in
`122-diagnose-full-suite-segfault_COMPLETED.md`'s Findings section — read
that first, don't re-diagnose.

**Root cause, in one line:** `run_case()`'s "free any Node whose EventBus
connection is new since this case started" teardown can't distinguish a
genuinely leaked off-tree test `Screen` from `autoload/GameState.gd`'s own
`_ready()`-time `EventBus.shared_stock_increased` connection, which only
*looks* new because it was deferred (per ticket 123's separate finding) and
this happened to be the first case to flush a frame.

**Blocked by:** None. `122-diagnose-full-suite-segfault_COMPLETED.md` is
done; this is its designated fix ticket.

**Status:** ready-for-agent

- [ ] `test_base.gd`'s teardown must never `queue_free()` (or, ideally,
      never even `disconnect()`) a target that is one of the project's
      registered autoloads. Suggested approach: capture the live autoload
      set once (e.g. `tests/test_runner.gd`'s `_initialize()` snapshotting
      `root.get_children()` before any test file runs, alongside its
      existing `GameData.load_all()` force-call) and have
      `_disconnect_and_free_new_eventbus_connections` skip any target whose
      instance ID is in that set. Off-tree leaked `Screen` nodes are never
      part of that snapshot, so the existing ticket-116 behaviour for its
      actual intended targets is unaffected.
- [ ] Consider also applying ticket 123's own proposed direction as
      defense-in-depth: have `test_runner.gd` force-flush one real engine
      frame up front (same spirit as its existing forced `GameData.load_all()`
      call), so every autoload's deferred `_ready()` — not just
      `GameState`'s — has already run before the first case's "before"
      snapshot is taken. This closes the timing hazard at its source rather
      than only at the teardown's blast radius, and independently fixes (or
      at least changes) ticket 123's run-order-dependent flake. Coordinate
      with ticket 123 if it's still open — don't duplicate work if it lands
      first.
- [ ] Add a regression test: a case using `await tree.process_frame` for
      the first time in a fresh process must leave `GameState` (checked by
      identity/instance id, not just non-null) alive and functional
      afterward. This needs to run in a process where no prior case has
      already flushed a frame — either a small standalone test file placed
      early enough in discovery order, or a dedicated harness invocation —
      confirm which is more robust before committing to one.
- [ ] After the fix, `scripts/run_tests.sh` must pass cleanly with zero
      segfaults across at least 5 consecutive full runs (the repro rate
      confirmed in ticket 122 was ~100%, so a handful of clean runs is
      sufficient signal — no need for a long soak).
- [ ] Update `CODEMAP.md` if `test_base.gd`'s or `test_runner.gd`'s
      responsibilities change in a way its existing entry no longer
      describes accurately.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep
content/tuning in data, gameplay state serializable, mutations in systems
and presentation outside them. Update canonical/domain/ownership
documentation when responsibilities or approved mechanics change. After
every GDScript edit run the required autoload-aware syntax check, then the
full headless suite before completion; report device-only checks separately
and flag new prose with PROSE-REVIEW.
