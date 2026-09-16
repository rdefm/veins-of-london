# 08 — District event deck engine

**What to build:** the deck engine per D5 — the `choices` card type (`{type:"choice", text, choices:[{label, effects, result_text}]}`), the trigger (`chance(0.25)` on completing travel or prospect), deck filtering by `district`/`excludeIfFlag`/`barometer state` (the last confirmed-unused plumbing for now — see D5), no-repeat-within-5-days via `state.world.recentEvents`. No event content yet — that's ticket 09.

**Blocked by:** 02 (needs prospect/travel actions to hook the trigger onto).

**Status:** done

- [x] `choices` card type implemented in the existing event runner (M0-T13 framework)
- [x] Trigger fires with the correct 0.25 probability on travel-or-prospect completion
- [x] Deck filtering respects `district` (or `"any"`) and `excludeIfFlag`; `barometer state` filter field is implemented and readable but need not be exercised by any current data
- [x] No-repeat-within-5-days enforced via `state.world.recentEvents`
- [x] Tests: filter/weights correctness, no-repeat window, `excludeIfFlag` exclusion behaviour
- [x] `godot --headless --check-only --script` clean on all touched files (full headless test suite green — 322/322; per-file `--check-only` is broken in this sandbox even on unmodified baseline files, autoloads unresolved — see task report)
