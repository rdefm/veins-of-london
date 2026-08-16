# Spec — Phone-as-OS shell: app grid, dock, and the retirement of the You tab

**Status:** Grilled and agreed with Richard, 2026-08-16. No open questions — Rest and
the home-raid trigger both move to HQ (see below). Final app roster and icon art are
deliberately deferred, not blocked.

## Why

The Phone tab today is a list of four cards with emoji titles, sitting alongside four
peer tabs. Richard wants it to read as an actual phone — apps, icons, notifications —
and wants the You tab dissolved into it so the nav shell gets simpler.

The design conclusion we reached is stronger than a reskin: **the game does not
simulate a phone, it *is* one.** This is a mobile game; the player's real device and
the player character's device are the same slab of glass, and that collapses the
fiction gap to zero — but only if we never draw a fake device. A rendered bezel, notch,
or fake clock/battery strip sits directly below the player's *real* status bar showing
their *real* time and battery, and the mismatch reads as a toy. So: full bleed, no
bezel, no fake system chrome. The Phone home screen becomes the game's home screen,
the bottom bar becomes the dock, and Map and HQ become apps you can also reach from it.

A secondary conclusion: an icon grid alone is a *directory* (it answers "where is
everything?"), so the hub value comes from the notification layer on top of it — the
day's texts, headlines and events surfacing as toasts, with a full log app behind them.

## Decisions

### Framing and chrome

- **Phone is the OS.** The phone home screen is the game's home screen. Map and HQ are
  apps, reachable from both the dock and the app grid.
- **Full bleed. No device chrome.** No bezel, no notch, no wallpaper-drawn phone body,
  and explicitly **no fake status bar** (no fake clock, carrier, or battery) — the real
  one is 10px above it and the clash is what kills the effect.
- **The existing `TopBar` becomes the status bar.** Same real, meaningful data it
  already carries (cash · day/time-block · bag button) — restyled thinner, denser, more
  subdued so it reads as system chrome rather than a game HUD. Behaviour and visibility
  rules unchanged (still hidden on `title`/`intro`/`map`; the Map screen keeps its own
  local top bar, which already carries a bag button).
- **The `NavBar` becomes the dock:** three pinned slots — **Phone · Map · HQ**. The
  Phone slot is a home button: pressing it from anywhere returns to the app grid, and
  pressing it while already on the grid does nothing.
- **Bag and You tabs are removed** from the bar (see below for where their content goes).

### App grid

- Icon-and-label tiles in a grid. **The final app roster and icon count are deliberately
  not locked in this spec** — see "Open, deferred" — but the grid, the tile component,
  and the lock treatment are all built to be roster-agnostic.
- **Icons are imported texture assets, never emoji.** Emoji and most non-ASCII glyphs
  render as blank tofu on the exported build — this is a repeatedly-documented, verified
  fact in this codebase (`icons.gd`'s `draw_home` comment; `map_canvas.gd`'s "✉" pin
  comment; `ore_glyphs.gd`). The current tiles' `💬 🗒 🤝 📰` are almost certainly
  already invisible on-device. Richard will generate icon art; the spec's job is to
  define the asset contract and ship a text fallback so the grid is testable before art
  lands. This supersedes M1.5 N6's "exactly 8 hand-drawn glyphs, nothing added" rule for
  *app icons specifically* — `Icons.draw_*` remains the mechanism for map/legend glyphs.
- **Locked apps show greyed with a padlock overlay** (`Icons.draw_padlock` already
  exists). Every app occupies its slot from day one, so the player can see the shape of
  the game ahead. This replaces the current locked-Map hack, where the whole tab label
  is overwritten with the string "Stick close for now — Archie" (`nav_bar.gd:23`); the
  Map app's `archiePartnerSeen` gate becomes a padlock, with that line moved to a
  tooltip/toast. The same greyed-plus-padlock treatment applies wherever a locked app
  appears, dock included.
- **Badges:** unread/attention dots on app tiles, driven by the predicates already in
  `phone.gd` (`_has_pending_messages()`, `_has_ticker_rumblings()`).

### Apps

Existing apps keep their content unchanged: **Messages**, **Notes**, **Factions**,
**Ticker** (including its axis drill-down). Three apps are new:

- **Profile** — absorbs the You tab's genuinely homeless content: HP + bar, attack
  range, the three skills with XP (crafting, cultivating, stealth), and the read-only
  equipped weapon/device summary. **Deliberately excluded:** cash and day (the status
  bar has them) and the Ops card (veins held / ore in stock — duplicated by the bag
  drawer and HQ's stored ore). Profile inherits You's designation in `M1-LONDON.md` D4
  as the landing site for **reputation (M2), affinities (M3), and Fieldcraft (M2)**.
- **Notifications** — the full notification log, newest first. Read-only.
- **Save/Load** — **one icon, one app**, holding all of: the three slots (Save / Load /
  Delete per slot), export, import, and **New Game**. New Game must be
  confirmation-gated; nothing in this app may commit a destructive action in one tap.
  Rationale: in a game whose flagship feature is Rewind, an accidental tap that discards
  the run is the worst possible failure mode.

### Notification rework

Today `state.notifications` is an unbounded array rendered as a top-anchored stack that
**only clears on tap** — nothing auto-expires (`notify.gd`, `notification_toast.gd`).
The new behaviour:

- **Toasts:** at most **2 visible** at once, auto-fading after a few seconds. Overflow
  **queues** — as one fades the next slides in, so a five-notification daily tick drains
  over a few seconds rather than being dropped or stacking down the screen.
- **Tap dismisses only.** No deep-linking from a toast (deliberate: a mis-tap during
  combat shouldn't navigate). Dismissing removes it from *view*, not from the log.
- **The log persists.** Entries gain a `seen` flag rather than being deleted, and the
  log is **capped at the 50 most recent entries** so the save file can't grow without
  bound.
- **State purity:** auto-dismiss timing must NOT be stored in state — no Timer, no Node,
  no Callable ever enters `GameState.state`. The `NotificationToast` component owns all
  timers; state holds pure data only (`{ id, text, seen, day }`). This is the constraint
  that keeps save/snapshot/Rewind working.
- **Rewind interaction:** the log lives in state, so it rewinds with everything else.
  That is intended, not a bug — a rewound day should not remember notifications that
  no longer happened.

### Bag drawer promotion

The `BagDrawer` is promoted from read-only quick-peek to **full inventory management**:
equip/unequip weapon, equip/unequip device, and device start / build attempt / abandon —
i.e. everything that today exists *only* on the `inventory` screen
(`inventory.gd:99–151`). This is what makes removing the Bag tab safe; without it, device
crafting becomes unreachable.

- **Gated in combat and events.** During combat, and during an event card with
  `itemHooks`, the drawer behaves **exactly as it does today** — read-only contents plus
  the legal Use buttons. Management controls are hidden there. This is a balance
  guardrail, not a polish detail: the drawer opens mid-fight from any screen (D4.4), so
  an ungated drawer would let a player re-optimise their loadout every turn for free,
  making weapon and device choice meaningless.
- The drawer becomes taller and scrollable outside those contexts. It must not swallow
  drag-to-scroll (see the `MOUSE_FILTER_PASS` precedent and bugfixes ticket 16).

### Screen retirement and routing

Four screen ids go away: **`you`**, **`bag`**, **`inventory`**, **`home`**.

- `you` → deleted; content split between Profile and Save/Load apps.
- `bag` (an alias id pointing at `inventory.gd`) → deleted; the drawer replaces it.
- `inventory` → deleted once the drawer does management. Its one remaining live call
  site is `combat.gd:512`'s raid-win routing; recommended replacement is to land on the
  phone home with the bag drawer opened (`Bag.open()`), which shows the loot in the new
  canonical place.
- `home` → **the phone app grid becomes the game's home.** `Nav.go_to("home")` lands
  there. Call sites to reroute: `combat.gd:495/507/512`, `modal_layer.gd:204`,
  `debug_start.gd:121`, and every `UI.back_button("home")` across the project.
- **Save migration:** an old save with `currentScreen` set to a retired id must not
  soft-lock. `Main.gd` currently falls back to `title` for unknown ids, which would drop
  a loaded game onto the title screen — map retired ids to `home` instead.
- **In-app navigation:** apps use `PhoneNav.go_home()` (already exists) for their back
  affordance, not `UI.back_button("home")`. Drill-downs inside an app (e.g. Ticker →
  axis detail) keep their own in-app back.

### Rest and the home-raid trigger move to HQ

Retiring `home` orphans two things that exist nowhere else. **Both move to HQ**
(decided with Richard, 2026-08-16) — doctrinally correct, since HQ is where base
actions belong ("things that happen at your bench go in HQ").

1. **Rest.** `home.gd:88` holds the only `TimeSystem.do_rest()` button in the game — the
   only way to end a day and heal. It becomes an HQ action. HQ is where you'd actually
   sleep, so this reads better than it did on the old flat home screen.
2. **The home-raid trigger.** `home.gd:18` fires `home_raid_intro` from the screen's
   `_ready()`, implementing R§3.8's documented "on next visit to home screen, launch"
   contract. The check moves to **HQ's `_ready()`**, following the same one-shot pattern:
   check the flags *before* building the screen's UI and return early if the event
   starts, since starting it navigates away and frees the node. A raid on your property
   firing when you next visit your property is closer to the fiction than firing when
   you next unlock your phone. `REFERENCE.md` §3.8's wording is amended to match
   ("on next visit to HQ") — canon amendment 5 below.

Note for the implementer: HQ's `_ready()` now carries a pre-build event check it did not
have before. Follow `home.gd:13–20`'s comment and structure exactly — it documents why
the check must come before `_refresh()` is connected.

Also audit the rest of `home.gd` before deleting it: its to-do card is already duplicated
by the Notes app, its Save & Load button becomes the Save/Load app, and its Inventory
button and collapsible stats card are superseded by the drawer and Profile — but confirm
nothing else is load-bearing.

### Canon amendments

These override existing spec text. Per the project constitution the agent may not
redesign canon unilaterally, so these are tracked as an explicit first ticket:

1. **`REFERENCE.md` §2.2** — screen roster: remove `you`, `bag`, `inventory`; `home`
   becomes the phone app grid; the tab bar becomes a 3-slot dock (Phone · Map · HQ).
2. **`M1-LONDON.md` D4** — the interface doctrine currently frames Map (addresses),
   Phone (people) and HQ (bench) as three *peer* places. Amend: Phone is the OS shell;
   Map and HQ are apps within it, pinned to the dock. The addresses/people/bench split
   still governs *where content lives*, just not the nav topology.
3. **`M1-LONDON.md` D4** — the "You" tab entry is deleted; its listed future content
   (reputation M2, affinities M3, Fieldcraft M2) is redesignated to the Profile app.
4. **`M1-LONDON.md` D4.4** — "Read-only everywhere, EXCEPT..." no longer holds. Amend to:
   full management outside combat and events; read-only plus Use buttons inside them.
5. **`REFERENCE.md` §3.8** — home-raid trigger wording: "on next visit to home screen,
   launch" becomes "on next visit to HQ, launch", per the section above.

## Constraints for implementers

- **No emoji in any new UI string.** They render as blank tofu on the exported build.
  Use imported texture icons, `Icons.draw_*` vectors, or plain ASCII text.
- **Architecture is non-negotiable:** screens render and call system functions; systems
  are static funcs mutating `GameState.state` and emitting `EventBus.state_changed`; no
  Node, object reference, or Callable ever enters state. `PhoneNav` gains the new app ids
  (`profile`, `notifications`, `saveload`); screens never mutate `state.phoneNav` directly.
- **After editing any `.gd`:** `godot --headless -s scripts/check_runner.gd -- <file>`,
  then `scripts/run_tests.sh`. Every ticket ships its tests.
- **Layout hazards are well-documented in this codebase and will bite:** autowrapping
  `Label`s collapse to one character per line inside an `HBoxContainer` unless given
  `SIZE_EXPAND_FILL` or `AUTOWRAP_OFF`; `PanelContainer`/`ProgressBar` default to
  `MOUSE_FILTER_STOP` and swallow drag-to-scroll. Read the comments in `ui.gd` before
  building the grid.
- **New prose** (app names, lock messages, confirm dialogs, empty states) is drafted
  against `docs/CONTENT-GUIDE.md` and flagged `PROSE-REVIEW:` in the task report.
- Every ticket with UI ends its report with a short **on-device QA checklist** — the
  agent cannot see the UI; Richard is visual QA.

## Explicitly out of scope / deferred

- **Final app roster and icon count.** Whether Factions folds into Messages, whether
  Map and HQ also get grid tiles alongside their dock slots — decided in the roster
  ticket, not here. Everything is built roster-agnostic.
- **Icon art itself.** Richard generates it later; tickets ship the asset contract plus
  a text fallback.
- **Wallpaper art** for the grid background.
- **Toast deep-linking** into source apps — considered and rejected for now (mis-tap
  risk in combat); the Notifications app covers deliberate browsing.
- Any change to Messages / Notes / Factions / Ticker *content*. They are re-hosted, not
  rewritten.

## Tickets

Dependency-sorted. A fresh chat should expand each into `.scratch/11-phone-os-shell/issues/`.

- **01 — Canon amendments.** All five doc edits above. Blocked by nothing.
- **02 — App icon asset contract + app tile component.** Asset path/size/naming
  convention, tintable single-colour requirement, `Texture2D` loading with a text
  fallback when a file is absent, and a reusable tile (icon + label + badge dot + locked
  state). Buildable and unit-testable standalone.
- **03 — Phone home grid.** The grid itself, the app registry, badge wiring to the
  existing predicates, locked/padlock treatment. Blocked by 02.
- **04 — Dock restructure.** `NavBar` → 3 slots (Phone · Map · HQ); Phone acts as a home
  button; Bag and You tabs removed; Map's lock becomes the padlock treatment. Blocked
  by 03.
- **05 — Status bar restyle.** `TopBar` visual pass; no behaviour change.
- **06 — Profile app.** HP, attack range, three skills + XP, read-only equipment.
  Blocked by 03.
- **07 — Save/Load app.** Slots, export, import, confirm-gated New Game. Blocked by 03.
- **08 — Notification log + toast rework.** `seen` flag, 50-entry cap, max-2 visible,
  queue-and-fade, timers in the component not in state.
- **09 — Notifications app.** Log viewer. Blocked by 03 and 08.
- **10 — Bag drawer promotion.** Full management outside combat/events; gated inside
  them; scrollable sheet.
- **11 — Relocate Rest and the home-raid trigger to HQ.** Must land *before* the
  retirement ticket deletes `home`, so the game never has a window with no way to rest.
  Ships with tests covering the relocated one-shot raid trigger. Blocked by nothing.
- **12 — Screen retirement and routing cleanup.** Delete `you`/`bag`/`inventory`/`home`;
  reroute every call site; retired-id save migration; final audit of `home.gd` for
  anything else load-bearing. Blocked by 04, 06, 07, 10, 11.
