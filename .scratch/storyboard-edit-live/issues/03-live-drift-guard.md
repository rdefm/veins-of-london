# 03 — Live-drift guard

**What to build:** When a working copy is imported, the tool records a fingerprint of the live file. If the live file has since changed (another edit, another branch), the board and the Promote confirm say so, so a promote never silently overwrites newer live content. After a successful Promote the working copy counts as in sync.

**Blocked by:** 02 — Working copy remembers its live source.

**Relevant files:** `tools/storyboard.html` (`promoteBoard`, `promoteSummary`, `loadProposals`, `renderEditBar`), `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `data/events/*.json`.

**Status:** ready-for-agent

- [ ] Import stores a fingerprint of the live file text in the working copy
- [ ] Board shows a "live file changed since import" notice when the fingerprint no longer matches
- [ ] Promote confirm names the drift and the user must confirm to overwrite; CLI `promote_storyboard.js` refuses unless forced
- [ ] After Promote the fingerprint updates and the notice clears
- [ ] Working copies with no fingerprint (older ones) show no notice and promote as before
- [ ] Tests cover match, drift, post-promote and missing fingerprint
