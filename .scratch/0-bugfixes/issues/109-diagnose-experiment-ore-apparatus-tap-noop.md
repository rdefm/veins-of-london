# 109 — Diagnose: tapping ore container / apparatus during Experiments does nothing

**What to build:** New recipe discovery in the lab bench is currently unreachable: tapping an ore container and/or an apparatus during an experiment does nothing, with no feedback and no state change. This ticket is diagnosis only — identify the root cause and report back (what's broken, why, and what a fix would involve). Do not implement a fix as part of this ticket; the fix will be scoped separately (either folded into this ticket or spun off as a new one) once the cause is known.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Root cause identified for why tapping an ore container during an active experiment attempt produces no visible effect.
- [ ] Root cause identified for why tapping an apparatus during an active experiment attempt produces no visible effect (may be the same cause as the ore-container case, or distinct — confirm which).
- [ ] Findings written up in this ticket's comments: what's broken, why, and a rough sketch of what fixing it would involve.
- [ ] No code changes required for this ticket beyond what's needed to observe/confirm the cause (e.g. temporary logging), unless the fix is trivial enough to include — use judgement and note the decision in the writeup.
