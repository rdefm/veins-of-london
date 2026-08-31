# 03 — Command deck: 3 action cards + Dial widget

**What to build:** Below the stage window, the command deck per §2.5:

- **Action deck — 3 cards, not 4.** Attack / Item / Run, a visual re-skin of
  today's `_build_action_bar()` (`scenes/screens/combat.gd:91`) as cards
  instead of plain buttons — same handlers (`Combat.player_attack()`,
  `Bag.open()`, `Combat.flee()`), no new inventory/hand mechanic, no
  energy-cost numbers.
- **The Dial — a distinct widget, not a card.** Docked right, full height,
  spanning both the action-card row and the log below it. **Rotate**
  (drag/swipe around the handle) cycles through `player.dial.
  loadedComplications` only. **Trigger** (press) casts the currently-selected
  complication via `Combat.cast_complication(index)`
  (`systems/combat.gd:1003`) — this **replaces** the plain button list
  currently in `scenes/components/bag_drawer.gd:352-359` for in-combat
  casting; the Bag drawer keeps handling non-Dial items. **Charge remaining**
  renders as an analog clock-face built into the top of the handle (not pips
  or a linear meter), reading `dial.currentCharge`/`dial.maxCharge`. If
  `loadedComplications` is empty, the widget doesn't render.
- **Speed toggle + player stats** sit in their own row at the bottom of the
  command deck, full width beneath the Dial strip's span.

Placeholder art: the Dial renders as plain vector/drawn shapes (a circle
handle with a rotating bezel indicator drawn via `_draw()` or primitive
`Control` nodes) — **not** the pixel-art diegetic prop §2.5 specifies. That
is the one deliberate pixel-art exception in the whole vision doc, and it's
deferred rather than placeholder'd with a flat box, since the widget's
functional shape (rotate/trigger/charge-clock) is what this ticket proves,
not its final look.

**Blocked by:** 01 (deck sits below the new stage layout; same screen
restructure)

**Assets needed:** none for this ticket. Real asset for later (not
currently ticketed — flag to the human when scheduling): 1 pixel-art Dial
prop sprite, per §2.5's locked physical-design description (thick handle,
dial built into the top as continuous material, elevated three-quarter
angle, distinct rotating-bezel texture band with raised notches and a fixed
pointer marker — art must not imply a fixed notch count since
`capacityMax` varies by Dial level/complication).

**Status:** ready-for-agent

- [ ] Attack/Item/Run render as 3 cards, calling the same handlers as
      today's action bar with no behaviour change
- [ ] Dial widget is docked right, full height, spanning the action-card row
      and the log region
- [ ] Rotate gesture cycles the selection through `loadedComplications`
      only (unloaded capacity is not selectable, matching today's
      `Dial.cast_complication()` behaviour)
- [ ] Trigger casts the selected complication via `Combat.cast_complication`
      and surfaces the same result/log line the old bag-drawer button did
- [ ] Charge-remaining renders as an analog clock-face reading
      `dial.currentCharge`/`dial.maxCharge`, visible without opening any
      menu
- [ ] Widget doesn't render at all when `loadedComplications` is empty
- [ ] `scenes/components/bag_drawer.gd`'s Dial-cast button list
      (`_on_cast_complication`) is removed from the in-combat Bag drawer —
      Dial casting only happens through the new widget; non-Dial Bag items
      (time pearl, shield, etc. bought outside crafting-into-Dial) still
      work via the existing Bag flow
- [ ] Speed toggle + player stats render in their own full-width row beneath
      the Dial's span
