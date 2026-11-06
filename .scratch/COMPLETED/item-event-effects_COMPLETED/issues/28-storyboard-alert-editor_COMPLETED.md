# 28 — Storyboard: alert editor + Blast double-raise warning

**What to build:** On option effects and on each outcome's effects, a structured alert editor: signed add, or raise-to-at-least a tier (shown by tier name: Unseen, Suspicious, Alarm), plus an optional cover (base, text). It edits only `alert` ops and preserves every other effect verbatim; other effects stay read-only. The tool warns when an option uses Blast and also carries its own raising alert op.

**Blocked by:** 22, 25

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `tools/promote_storyboard.js`, `data/constants.json` (alert tier names); REFERENCE §3.9a (alert op, cover).

**Status:** ready-for-agent

- [ ] Tests: alert edits touch only `alert` ops; other effects untouched; Blast double-raise warning fires
- [ ] Full serialise → re-import → promote round trip keeps tags, exclusions, item effects and alert ops
- [ ] Tool warning strings PROSE-REVIEW
