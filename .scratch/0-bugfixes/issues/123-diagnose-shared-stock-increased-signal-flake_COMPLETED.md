# 123 — Diagnose EventBus.shared_stock_increased-dependent test flake

**What to build:** Not a code fix — a written diagnosis. `test_contracts.gd`'s
`staffed_sales_closes_a_fully_stocked_delegated_period_immediately` case
(which calls `EventBus.shared_stock_increased.emit()` directly and expects
`Contracts.shared_stock_increased()` to have run as a result) fails
intermittently depending on where it falls in the full suite's run order —
confirmed failing when `test_contracts.gd` runs early/in isolation, but
observed passing inside a full `run_tests.sh` run. Pin down why the result
depends on run position before anyone patches anything.

**Leading lead, not yet confirmed root cause:** `autoload/GameState.gd`'s
`_ready()` is the only autoload `_ready()` in the project that connects an
`EventBus` signal (`EventBus.shared_stock_increased.connect(_on_shared_stock_increased)`).
`tests/test_runner.gd`'s own top comment already documents that autoload
`_ready()` callbacks are deferred and never get a chance to run under a
synchronous `-s SceneTree` script with no frame loop — which is why it
force-calls `GameData.load_all()` manually rather than relying on
`GameData`'s own `_ready()`. `GameState._ready()`'s `EventBus` connection may
have the identical problem: if no engine frame has been processed yet when a
test emits `EventBus.shared_stock_increased` directly, the autoload's
listener may not be connected yet, so the emit is a silent no-op. If some
earlier test file's case happens to `await` a real engine frame (per
`test_base.gd`'s own comment on this), that could flush the deferred `_ready()`
queue and make the connection "appear" for every test after it in the same
process — explaining why the result depends on run position. Confirm or
refute this rather than assuming it.

**Blocked by:** None — can start immediately.

**Status:** done

- [x] Confirms (or refutes) that `GameState._ready()`'s `EventBus` connection
      is genuinely not established at the point this test's `emit()` call
      runs, when `test_contracts.gd` is executed standalone/early
- [x] If confirmed: identifies what specifically causes the connection to
      become active partway through a full suite run — which earlier test
      file/case is the first to trigger an actual engine frame (e.g. via
      `await (Engine.get_main_loop() as SceneTree).process_frame`, per
      `test_base.gd`'s documented escape hatch), and confirms that's the
      trigger by checking whether the failure reappears when that file is
      excluded/reordered
- [x] Checks whether the same latent dependency affects `tests/test_payroll.gd`,
      the only other test file that also calls
      `EventBus.shared_stock_increased.emit()` directly (both are the only
      two test files exercising this specific signal+autoload path — other
      files under `grep -rl "EventBus\.\w*\.emit()" tests/` emit different
      signals with no autoload `_ready()`-side connection, so are likely
      unaffected, but confirm rather than assume)
- [x] Findings written up on this ticket (or a short doc referenced from it)
      with a reproducible before/after (e.g. running `test_contracts.gd`
      alone vs. after a file that's confirmed to flush a frame)
- [x] Writes a new ticket (next number after this one, `ready-for-agent`)
      capturing the confirmed root cause and a proposed fix approach — see
      **Findings** below for why this was superseded rather than filed as a
      fresh ticket

## Findings (2026-09-16)

**Hypothesis confirmed.** `GameState._ready()`'s
`EventBus.shared_stock_increased.connect(...)` is deferred like every other
autoload `_ready()` under the headless `-s SceneTree` runner, and does not
exist on `EventBus` until the process flushes at least one real engine
frame. Before that point, `EventBus.shared_stock_increased.emit()` is a
silent no-op as far as `GameState`/`ContractsSystem` are concerned.

Repro (pre-124 behaviour, replayed with a temporary scratch runner that
copied `test_runner.gd`'s old `_initialize()` — no `process_frame` flush —
restricted to a single file, then deleted afterward):

```
$ godot --headless -s scripts/_scratch_ticket123_old.gd   # test_contracts.gd alone, no flush
FAIL: staffed_sales_closes_a_fully_stocked_delegated_period_immediately
      assert_eq: got 1, expected 0.
      assert_eq: got 0, expected 1.
      assert_eq: got 0, expected 20.
TOTAL: 13 passed, 1 failed
```

Same file, same case, with a `process_frame` flush added up front (the
post-124 `_initialize()` shape) restricted to the same single file:

```
$ godot --headless -s scripts/_scratch_ticket123_new.gd   # test_contracts.gd alone, with flush
PASS: staffed_sales_closes_a_fully_stocked_delegated_period_immediately
TOTAL: 14 passed, 0 failed
```

This isolates the variable cleanly: same file, same case, same run order,
the only difference is whether a frame was flushed before it ran — and
that alone flips the result. Confirms the connection genuinely isn't live
until a frame flushes, not something else about full-suite ordering.

**Which file used to trigger the flush in a full run:** already pinned down
by `122-diagnose-full-suite-segfault_COMPLETED.md`'s own isolation
experiments (same underlying deferred-`_ready()` hazard, discovered while
diagnosing the segfault) — `test_hq_lab_bench.gd`'s
`hq_lab_bench_right_arrow_tweens_the_diorama_pan_when_in_a_live_tree` case,
the first of 5 files that `await process_frame`, in file-discovery order.
122's before/after (excluding all 5 `process_frame` files vs. running
`test_hq_lab_bench.gd` alone) already confirms this is the trigger; no need
to re-run that experiment here.

**`tests/test_payroll.gd`: same latent dependency, but does not manifest as
a flake.** Its
`unpaid_sales_role_blocks_realtime_delegated_delivery_and_offer_sourcing`
case also calls `EventBus.shared_stock_increased.emit()` directly, but its
assertion (`delivered_qty(contract) == 0`) is insensitive to whether
`GameState`'s listener actually ran: the case's whole point is that an
unpaid Sales role blocks delivery, so `Contracts.shared_stock_increased()`
running and doing nothing (blocked by the unpaid role) is indistinguishable
from the signal being a no-op. Confirmed by running the file standalone
with the pre-124 (no-flush) runner shape — passes 9/9, no failure:

```
$ godot --headless -s scripts/_scratch_ticket123_old_payroll.gd   # test_payroll.gd alone, no flush
TOTAL: 9 passed, 0 failed
```

Not a coverage gap worth fixing here — the case's intent (payroll gating)
doesn't need the connection to be live to be a valid test — just noting it
for the record since the ticket asked to confirm rather than assume.

**Why no new fix ticket was filed:** ticket 124 (landed in this same branch
history, commit `c8c9039`, immediately before this diagnosis) already
implemented and verified the exact fix this ticket would have proposed —
`test_runner.gd`'s `_initialize()` now does `await process_frame` once,
up front, before any test file runs, closing the timing hazard at its
source for every autoload, not just `GameState`. 124's own checklist
explicitly called this out as "independently fixes (or at least changes)
ticket 123's run-order-dependent flake" and asked to coordinate rather than
duplicate work if it landed first — it did. Re-ran the full suite after
confirming the above (`scripts/run_tests.sh` equivalent,
`godot --headless -s tests/test_runner.gd`): 2458 passed, 1 failed (the
same pre-existing unrelated `test_playthrough.gd` save-roundtrip failure
124's own resolution already flagged), zero segfaults, ~93s — consistent
with 124's verified fixed state. Filing a fresh "diagnose and propose a
fix" ticket for something already fixed and verified would just be
duplicate busywork; closing this ticket as `done` with the confirmation
recorded here instead.

No production code was changed by this ticket. The scratch runner scripts
above were created under `scripts/_scratch_ticket123_*.gd` for
reproduction purposes only and deleted before commit — the exact commands
are reproducible from this write-up if anyone needs to re-verify.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
