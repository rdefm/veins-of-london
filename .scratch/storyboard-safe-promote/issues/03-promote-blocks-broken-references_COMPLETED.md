# 03 — Promote blocks broken references

**What to build:** Removing or rekeying a card or option can silently break other events, data files or game code that name it. Today the tool warns in the Promote confirm for some cases. After this ticket, Promote scans everywhere that can reference the event, refuses when anything would dangle, and names each broken reference and where it lives. The user can then fix it in the tool, with no Claude needed.

**References scanned:** event ids, card keys and option ids named in other events (choice conditions), other `data/*.json`, and `.gd` game code. The tool can't read code at promote time without help, so extend the exported lint reference file to carry those inbound references. It needs regenerating whenever code references change; a stale file must show as stale, not pass.

**Tests:** a key that appears only in `tests/` warns but doesn't block.

**Blocked by:** 02 — Card references survive renumbering

**Relevant files:** `tools/storyboard.html` (`inboundRefs`, `promoteSummary`, `lintDraft`, `promoteBoard`), `tools/promote_storyboard.js`, `tools/lint_refs.json`, `scripts/export_lint_refs.gd`, `tools/test_storyboard.js`, `tests/test_event_content_lint.gd`, `systems/events.gd` (`choice_record`, `current_card_key`)

**Status:** ready-for-agent

- [ ] Removing a card another event's condition names blocks Promote, naming the source
- [ ] Removing a card named in another data file or `.gd` file blocks the same way
- [ ] A reference found only in tests warns without blocking
- [ ] An edit that breaks nothing promotes with no extra step
- [ ] The Promote button and the CLI apply the same check
- [ ] Stale reference data is detected and reported
- [ ] Coverage in `test_storyboard.js`
- [ ] CODEMAP updated
