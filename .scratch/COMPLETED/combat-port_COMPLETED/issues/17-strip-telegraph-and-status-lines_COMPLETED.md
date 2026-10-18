# 17 — Strip's unused telegraph / status-line rendering

**What to build:** `TurnOrderStrip` still renders three optional entry fields on the focused card — `statusLines` (Array[String]), `telegraphText` and `tellImage` (the enemy-ability "Intent: …" slot and its `combat_visuals.json` `tell` pose) — but no caller fills them any more: the round screen's `strip_entries()` supplies `actionText`/`actionUnread`/`guardBadge`/`statusBadge` instead, and the builders that filled the three were deleted with the old engine. Decide, then do one of:

- **A. Remove (recommended):** round-fight intents (`actionText`, unread `?`) and `statusBadge` already cover what the telegraph and status lines showed. Delete the three fields' rendering (`NameplateCard` `status_lines` / `shows_telegraph_slot` / `telegraph_text` / `tell_image` / `telegraph_label`, the expanded-height cases that size for them, `SIGN_INTENT_ID`/`SIGN_STATUS_ID` if they go unused), the strip tests covering them, and the `tell` entries/rule in `data/combat_visuals.json` plus their GameData validation.
- **B. Wire up:** have `strip_entries()` fill them (e.g. the focused enemy's full intent list and its Table 4 statuses as status lines; `tellImage` from the template's `tell` pose when its next action is an ability use).

Needs the human's pick before work starts (it touches `docs/combat-animation-vision.md` §4.2 "Enemy telegraph" and the `tell` art slot in its §3 subject table).

**Blocked by:** None

**Relevant files:** `scenes/components/turn_order_strip.gd` (entry contract comment above `configure()`, `_expanded_height_for()`, `_build_card()`, `_build_card_content()`, `NameplateCard`); `scenes/screens/combat_rounds.gd` (`strip_entries()`, `_strip_entry()`); `tests/test_turn_order_strip.gd` (`expanded_card_bounds_long_name_three_statuses_and_long_intent`, the ability-tell pose cases); `data/combat_visuals.json` (`templates.*.tell`, `actionRule`); `autoload/GameData.gd` (combat_visuals validation of `tell`); `docs/combat-animation-vision.md` §3, §4.2; `CODEMAP.md` turn_order_strip row

**Status:** ready-for-human

- [ ] Human picks A or B
- [ ] No strip entry field is rendered that no caller can supply (A), or every field is filled from round-fight state (B)
- [ ] Full suite and `scripts/check_all.sh` clean; CODEMAP and the vision doc match
