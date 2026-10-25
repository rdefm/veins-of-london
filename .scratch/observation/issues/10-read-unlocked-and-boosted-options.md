# 10 — Read-unlocked and boosted options

**Phase:** MVP

**What to build:** The player sees that observing opened doors. Options gated by `observed` stay hidden until met (default `requires` display), then fade in when the sheet closes. Options unlocked or boosted by a read show that ore's glyph on the button. Boost mods appear in the check's ? modal with their author label.

**Blocked by:** 05.

**Relevant files:** `scenes/screens/event.gd`, `systems/events.gd` (choice visibility, mod labels), `tests/test_event_screen.gd`.

**Status:** ready-for-agent

- [ ] Hidden `observed`-gated option appears after sheet closes, with fade
- [ ] Unlocked/boosted options carry the earning ore's glyph
- [ ] ? modal lists observation boost as labelled modifier
- [ ] Human on-device check list in the report
