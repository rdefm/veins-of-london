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

**Status:** ready-for-agent

- [ ] Confirms (or refutes) that `GameState._ready()`'s `EventBus` connection
      is genuinely not established at the point this test's `emit()` call
      runs, when `test_contracts.gd` is executed standalone/early
- [ ] If confirmed: identifies what specifically causes the connection to
      become active partway through a full suite run — which earlier test
      file/case is the first to trigger an actual engine frame (e.g. via
      `await (Engine.get_main_loop() as SceneTree).process_frame`, per
      `test_base.gd`'s documented escape hatch), and confirms that's the
      trigger by checking whether the failure reappears when that file is
      excluded/reordered
- [ ] Checks whether the same latent dependency affects `tests/test_payroll.gd`,
      the only other test file that also calls
      `EventBus.shared_stock_increased.emit()` directly (both are the only
      two test files exercising this specific signal+autoload path — other
      files under `grep -rl "EventBus\.\w*\.emit()" tests/` emit different
      signals with no autoload `_ready()`-side connection, so are likely
      unaffected, but confirm rather than assume)
- [ ] Findings written up on this ticket (or a short doc referenced from it)
      with a reproducible before/after (e.g. running `test_contracts.gd`
      alone vs. after a file that's confirmed to flush a frame)
- [ ] Writes a new ticket (next number after this one, `ready-for-agent`)
      capturing the confirmed root cause and a proposed fix approach (e.g.
      making the test not depend on the autoload's real `_ready()` firing —
      calling `Contracts.shared_stock_increased()` directly instead of going
      through `EventBus.emit()`, the way this ticket's own investigation
      should establish is safe or not — or making `tests/test_runner.gd`
      force-flush a frame once up front, the way it already force-loads
      `GameData`) — no fix is implemented in this ticket

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
