# 04 — Occurrence queue projection + occurrence cards

**What to build:** The turn-order strip shows one card per upcoming turn occurrence, not one per combatant. A pure system query projects the bounded upcoming queue from the persisted cursor per ticket 01's policy: the front entry is whoever acts now, every living combatant's next turn is reachable, and repeated occurrences (including Motion extra turns) appear as separate cards in true scheduling order. The strip scrolls horizontally by drag; scrolling only moves the viewport — it never changes selection, spends anything or advances combat. All visible occurrences of the currently selected combatant share the selected treatment; tapping any of them selects that same combatant (selection itself stays enemy-focus-only until ticket 05 — non-enemy taps behave as today's non-enemy swipe). The front card is the one that will act when the player next issues a command or playback next advances.

Strip tests asserting the old collapse-to-one-card behaviour are replaced by occurrence-order assertions.

**Blocked by:** 02 — Two-region layout; 03 — Resumable turn progression.

**Relevant files:**
- `systems/combat.gd` — new projection query beside `build_turn_queue` (reads cursor state from 03)
- `scenes/components/turn_order_strip.gd` — `build_entries` (drop dedup), `configure`, `_rebuild`, `_build_card`, `card_key_string` (occurrence id vs combatant key), `handle_swipe`, `_gui_input`, `_end_drag`, `SWIPE_THRESHOLD_PX`
- `scenes/screens/combat.gd` — `_build_turn_order_strip`, `_selected_strip_pos`, `_on_strip_selection_changed`, `_init_ghost_tracker`/`_drain_ghost` (ghost keyed by combatant must fan to every occurrence card)
- `tests/test_turn_order_strip.gd` — "build_entries_collapses_motions_extra_queue_entries…", "build_entries_re_sorts_after_a_motion_boosted_extra_turn…", ordering and swipe cases
- `tests/test_combat_screen.gd` — "turn_order_strip_renders_one_card_per_living_combatant", "turn_order_strip_excludes_koed_combatants", swipe-routing cases
- `tests/test_combat.gd` — projection query cases
- `docs/REFERENCE.md` — §3.7a Turn order (projection policy from 01)
- `docs/combat-animation-vision.md` — §2.4 as amended by 01

**Status:** ready-for-agent

- [x] Projection query is pure (no state mutation, no RNG consumption) and returns occurrences in scheduling order with a stable per-occurrence id and the combatant key
- [x] Motion fixture: the player appears twice in sequence; a two-enemy fixture with speeds straddling the player's shows enemy/player/enemy interleaving matching `build_turn_queue`
- [x] Every living combatant has at least one occurrence in the projection; KO'd combatants have none
- [x] Strip renders one card per occurrence; card count equals projection length
- [x] Dragging the strip changes only its scroll offset — `GameState.state` is byte-identical before and after
- [x] Tapping the second occurrence of a combatant yields the same selection as tapping the first; both cards render selected
- [x] Ghost HP bars drain on every card of the damaged combatant
- [x] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP row for `turn_order_strip.gd` updated
