# 01 — Fast-lane wiring in the skill

**What to build:** After the user promotes from the storyboard tool and the proposal has no open "for Claude" comments, "wire <event>" is a short targeted check: the storyboard JS tests, the content lint, and only the Godot test files that mention the event id. No ticket is written, the full suite is not run, nothing is committed. A failure outside the event's own tests is reported to the user, not fixed in-session. Proposals with open comments keep today's full flow, except the full suite defers to commit / end of session.

**Blocked by:** None — can start immediately.

**Relevant files:** `.claude/skills/implement-storyboard-event/SKILL.md`, `tests/test_runner.gd` (takes test-file names as user args), `tools/test_storyboard.js`, `tests/test_event_content_lint.gd`, `.scratch/storyboard-fast-wire/spec.md` § Fast lane.

**Status:** ready-for-agent

- [ ] Skill picks fast vs full lane from the open-comment count and says which in its report
- [ ] Fast lane lists the exact commands (storyboard JS test, lint, grep-selected test files) and how to select the files
- [ ] Fast lane: no ticket, no full suite, no commit, no doc reads unless a failure needs one
- [ ] Out-of-scope failures are reported, not fixed
- [ ] Full lane defers the full suite to commit / end of session
