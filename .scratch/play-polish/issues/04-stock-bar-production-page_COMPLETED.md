# 04 — Stock bar on the BizBrief Production page

**What to build:** Each item on the Production page gets one easy control for "make this many, sell anything above that". It replaces the current Target slider row and sets the rule from ticket 03.

**Control**

- One horizontal bar per item, running from 0 to `productionTargetMax`.
- **Keep:** a handle that starts at the left-hand end and slides right, and the bar fills behind it. Production keeps making the item until stock reaches Keep.
- **Sell-above cutoff:** a separate handle that starts at the right-hand end and slides left. Stock above it can be auto-sold.
- The two handles meet but never cross: the cutoff stops at Keep, and sliding Keep right into the cutoff pushes the cutoff along with it.
- Stock needed for contracts counts inside the protected amount. If contract need puts the floor above the cutoff, the bar shows that, and nothing at or below the floor is sold.
- Current stock is visible on the same row.
- Mood is a simple Off / Careful / Steady / Eager choice under the bar, with a one-line meaning for the selected mood.
- A live line reports the result, e.g. "Today: would sell 6 at about £135", or why not ("Price too low", "Under your cutoff", "No one on Sales").

Before Sales is staffed, the cutoff and mood show as locked with a clear reason, while Keep still works.

Screens stay read-only: the control calls system functions, and the projection for the live line lives in the system. New UI strings are `PROSE-REVIEW:`.

**Blocked by:** 03 — Daily auto-sell pass

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_build_production`, `_build_production_recipe_row`, `_target_text`, `_production_status`), `scenes/components/map_card_style.gd` (`quantity_slider`), `systems/rooms.gd` (`set_lab_threshold`, `effective_lab_target`), `systems/auto_sell.gd`, `docs/ui-vision.md`, `tests/test_rooms.gd`

**Status:** ready-for-agent

- [ ] Keep slides right from the left end, fills the bar behind it, and sets the Production target
- [ ] The cutoff slides left from the right end, can't pass Keep, and is pushed along when Keep reaches it
- [ ] Contract-protected stock is visible and never shown as sellable
- [ ] Mood selection and cutoff persist through save and load
- [ ] The live line matches what the next rollover would actually sell for the same state (test it through the system projection)
- [ ] Locked state with a reason shows while Sales is unstaffed
- [ ] Both handles are easy to grab on a phone, including when Keep and the cutoff are close together
- [ ] No state mutation in the screen
- [ ] Human on-device check is listed in the task report
