# 04 — Whole-queue run, filters, resume

**Status:** ready-for-agent

**What to build:** `run` with no arguments queues every shot on every board in the drafts phase that has no approved draft yet. An approved draft is a per-draft `approve` verdict on one of its takes. `--event` and `--shot` narrow the queue.

A run is safe to interrupt. Every step (generate, judge, retry) is idempotent and recorded in the run log before the next starts. Re-running after a crash resumes from the log. Already-made takes are never regenerated and already-paid calls are never repeated, and no board, judgement or ledger file is left half-written.

The user's pick needs no new mechanism. Picking one take approves it through the existing per-draft verdict; the other takes are left without a verdict, not rejected. Picks, notes and rejections on autogen takes then reach `agreement`, `benchmark freeze` and `propose-rules` exactly as hand-made drafts do.

**Blocked by:** 02 — Spend ledger and caps; 03 — Retry failing takes.

**Relevant files:**
- `tools/art_judge/judge.py` (`plan_batch`, `judge_batch` for the queue/plan pattern; `Workspace.write_json`)
- `tools/art_judge/agreement.py` (`user_verdicts`: draft targets are repo paths)
- `tools/storyboard.html` (board `phase`, per-draft verdicts in `feedback.json`)
- `.scratch/event-art/*/board.json`, `.scratch/event-art/*/feedback.json`
- `.scratch/art-autogen/spec.md` (stories 4, 5, 16, 17, 19)

- [ ] Fixture: two boards, one in the drafts phase. Only its shots without an approved take are queued
- [ ] `--event` and `--shot` filters each narrow the queue
- [ ] A simulated crash mid-run, then a re-run: no take regenerated, no ledger cost double-counted, the run completes
- [ ] An `approve` on one autogen take removes that shot from the next run's queue and leaves its other takes verdict-free
- [ ] `agreement` counts verdicted autogen takes (fixture check)
