# 14 — Storyboard security conditions and site warnings

**What to build:** The condition picker gains security conditions for `requires` and `hideUnless`. Controls are feature (ward, guards, alarm, cameras, locks), then present, absent, at least or at most with a number where relevant. They write the existing `{security}` condition, using `atMost: 0` for absent. Hide and disable behave like other requires. The tool warns on site-dependent effects or conditions when an event has no site or vein.

**Blocked by:** 09, 13

**Relevant files:** `tools/storyboard.html`, `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `tools/test_quest_editor.js`, REFERENCE.md §3.9a Event choice checks

**Status:** ready-for-agent

- [ ] All five features can be picked for present, absent, at least and at most where relevant
- [ ] Output matches the condition the game already reads
- [ ] Hide and disable both work
- [ ] Warnings show on site effects and conditions with no site or vein
- [ ] Round trip and promotion are lossless
- [ ] Shared section is unchanged and the sync test is green
