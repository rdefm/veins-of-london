# 06 — Branch routing editing

**What to build:** From the card/branch editor the writer creates branches, sets a card's `goto {branch, card?}`, and sets a branch's `then`: single target, end, or an ordered conditional list using the existing `condition_met` vocabulary (flag, relation, cash, item, path, past choice) with a final else. Any link that would create a cycle is rejected with an explanation.

**Blocked by:** 04 — Card CRUD.

**Relevant files:** `tools/storyboard.html`, `tools/test_storyboard.js`, `systems/events.gd` (`condition_met` ~452 — vocabulary reference only), spec § Draft format.

**Status:** ready-for-agent

- [ ] Create / rename / delete branch (delete warns on inbound links)
- [ ] Card `goto` picker: branch + optional card
- [ ] `then` editor: single / end / conditional list; condition kinds match `condition_met`
- [ ] Cycle detection over the card graph is a pure node-tested function; editor blocks cycle-creating links
- [ ] All edits undoable and saved
