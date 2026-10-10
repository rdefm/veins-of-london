# 01 — Draft model + test harness (prefactor)

**What to build:** The storyboard tool understands the named-branch draft format (spec § Draft format). Its pure logic (parse/serialise draft, legacy flat-goto → branches conversion, play-order walk following `goto` and branch `then`) lives in a marked pure section of the HTML, unit-tested by a node test that extracts that section (same pattern as the quest-editor test). The read-only phone preview plays both branch drafts and older flat proposals.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (`parseProposal`, `proposalCards`, `optionMech`, `outcomesOf`), `tools/test_quest_editor.js` (extraction pattern), new `tools/test_storyboard.js`, `.scratch/writing-revamp/*-proposal*.md`, `.scratch/storyboard-editor/spec.md` § Draft format, REFERENCE.md §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Pure model section between explicit start/end markers; node test extracts it from the shipped HTML
- [ ] Parse → serialise round-trip lossless on a branch draft
- [ ] Legacy flat proposals (option/outcome `goto` card indexes) convert to named branches; every existing `.scratch/writing-revamp` proposal converts without error
- [ ] Play-order walk follows card `goto`, outcome `goto`, branch `then` (single, `"end"`, conditional list, omitted = end)
- [ ] Cards get stable auto `key`s when missing
- [ ] Preview renders a branch draft and a legacy proposal correctly
- [ ] `node tools/test_storyboard.js` passes; CODEMAP row updated
