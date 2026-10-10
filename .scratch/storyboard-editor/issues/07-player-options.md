# 07 — Player options + outcome routing

**What to build:** On a card the writer adds/removes player options (id, label, result text). Each outcome — plain result, success/fail, per-success-count — can be routed to an existing branch (optionally a card) or to a **new branch created in place**.

**Blocked by:** 06 — Branch routing editing.

**Relevant files:** `tools/storyboard.html` (`outcomesOf`, `optionMech`), `tools/test_storyboard.js`, REFERENCE.md §3.9a Event choice checks, spec § Decisions (Player options).

**Status:** ready-for-agent

- [ ] Add/remove/reorder options; edit id, label, result text
- [ ] Outcome routing picker incl. "new branch…" creating and linking a branch in one step
- [ ] Cycle rule enforced on outcome links
- [ ] Preview shows the options and follows the chosen outcome
