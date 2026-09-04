# 03 — Author-intent notes sidecar

**What to build:** A notes panel, available while editing any quest (existing, via ticket 01, or
new, via ticket 02), where Richard writes free plain text describing what he wants the
mechanical fields (effects/ops/deck/flags) to do per card or choice — for Claude to read and
code later. Saves as a sidecar Markdown file `data/events/drafts/<id>.notes.md`, keyed to the
quest id, auto-loaded whenever that quest is reopened in the tool. The real event JSON is never
touched by this feature — notes live only in the sidecar file.

**Blocked by:** 01, 02 — the notes panel wires into both the existing-quest editor and the
new-quest builder.

**Status:** ready-for-agent

- [ ] While a quest is open (existing or newly created), a notes panel is visible with a
      plain-text/Markdown textarea.
- [ ] Saving the quest also saves the notes panel's contents to
      `data/events/drafts/<id>.notes.md` (creating `data/events/drafts/` if needed).
- [ ] Reopening the same quest id auto-loads its existing `.notes.md` content into the panel if
      one exists; opening a quest with no notes file shows an empty panel.
- [ ] Notes are per-quest-id — opening a different quest shows that quest's own notes, not the
      previous quest's.
- [ ] Saving a quest's prose (ticket 01) or structure (ticket 02) never writes into or modifies
      the real `data/events/<id>.json` based on notes content — the two files stay fully
      independent.
