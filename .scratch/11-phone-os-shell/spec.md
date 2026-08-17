# Spec — Phone-as-OS shell: app grid, dock, and the retirement of the You tab

Status: `ready-for-agent`

Source discussion: grilled and agreed with Richard 2026-08-16; design-reviewed and amended 2026-08-17 (see Further Notes). Final app roster and icon art are deliberately deferred, not blocked — this spec is roster-agnostic by design.

## Problem Statement

The Phone tab today is a flat list of four cards with emoji titles (`💬 🗒 🤝 📰`), sitting as one peer among five tabs in the nav bar. It doesn't read as a phone, and it's about to break outright: emoji render as blank tofu on the exported build, so those card icons are already close to invisible on-device. Separately, the You tab has become a junk drawer — HP/skills content that belongs nowhere else sits alongside save/load and stat-summary content that duplicates the bag drawer and HQ, with no clean owner. The nav bar itself is flatter than the game's actual structure: Map (addresses), Phone (people), HQ (bench), Bag, and You all sit as equal peers, when conceptually Bag and You are content, not places.

## Solution

The phone home screen becomes the game's home screen. The player's real device and the player character's in-fiction phone are treated as the same object: full bleed, no drawn bezel/notch/wallpaper-phone-body, and no fake system chrome (no invented clock, carrier, or battery readout) sitting on screen. The build runs fullscreen, so there is no real OS status bar ever visible to align against — the justification for skipping fake chrome isn't proximity to something real, it's that faking system-level data the game has no business showing is decorative fiction with no function, and it reads as a toy the moment a player notices it's not real. The existing `TopBar` (cash · day/time-block · bag button) is restyled thinner and more subdued so it reads as system chrome rather than a game HUD, without claiming literal indistinguishability from a real one.

The nav bar becomes a three-slot dock: **Phone · Map · HQ**. Phone is a home button. Map and HQ remain full screens but are also reachable as dock-pinned "apps." Bag and You are removed from the bar entirely: Bag's functionality moves into an upgraded `BagDrawer` reachable from anywhere, and You's content splits three ways into new apps — **Profile** (HP, skills, equipment summary), **Save/Load** (slots, export/import, New Game), and **Notifications** (the persistent log). An app grid holds every app as an icon-and-label tile, including locked ones (greyed, padlocked, visible from day one so the player can see the shape of the game ahead). A new notification-toast layer surfaces the day's events on top of the grid, queued and auto-fading, backed by the same persistent log the Notifications app browses.

## User Stories

### Framing and chrome

1. As a player, I want the phone home screen to fill the entire display with no drawn bezel or fake device body, so that the game reads as my actual phone rather than a phone-shaped widget inside a game.
2. As a player, I want no fake clock, carrier signal, or battery indicator drawn anywhere in the game's chrome, so that I'm never looking at invented system data that doesn't mean anything.
3. As a player, I want the top status bar (cash, day/time-block, bag button) restyled thinner and more subdued than today's HUD-style bar, so that it reads as part of the phone's system chrome rather than a floating game overlay.
4. As a player, I want the status bar's behavior and visibility rules (hidden on title/intro/map, Map keeps its own local bar) to stay exactly as they are today, so that this is a visual pass, not a functional one.

### Dock and app grid

5. As a player, I want a three-icon dock — Phone, Map, HQ — always available, so that I can jump to any of the game's three top-level places from anywhere.
6. As a player, I want tapping the Phone dock icon from any screen to return me to the app grid, so that it acts as a reliable "home" button.
7. As a player, I want tapping the Phone dock icon while I'm already on the app grid to do nothing, so that it never causes a jarring re-navigation or flicker.
8. As a player, I want every app — locked or unlocked — to occupy a fixed slot in the grid from day one, so that I can see the shape of the full game ahead of me and apps never shuffle position as I unlock them.
9. As a player, I want locked apps shown greyed out with a padlock overlay instead of hidden or replaced with a hint string, so that "locked" is a consistent visual state I learn once and recognize everywhere (grid and dock alike).
10. As a player, I want app icons to be real imported image assets, not emoji, so that they're actually visible on the exported build.
11. As a player, I want a legible text fallback for any app whose icon art hasn't landed yet, so that the grid is fully testable and playable before final art exists.
12. As a player, I want unread/attention badges on app tiles (messages, ticker rumblings) so that I know at a glance which apps have something new without opening them.
13. As a player, when the Map app is still gated behind meeting Archie, I want to see it as a padlocked tile with an informative tooltip/toast rather than today's tab-label-overwrite hack, so that the locked state is consistent with every other locked app.

### Apps

14. As a player, I want Messages, Notes, Factions, and Ticker (including its axis drill-down) to keep working exactly as they do today, just reachable as app-grid tiles instead of home-screen cards, so that re-hosting them doesn't change anything I've already learned.
15. As a player, I want a Profile app showing my HP and HP bar, attack range, my three skills (crafting, cultivating, stealth) with XP, and a read-only summary of my equipped weapon and device, so that I have one place to check my character's current standing.
16. As a player, I want cash and day/time-block left out of Profile since the status bar already shows them, so that I'm not seeing the same numbers twice.
17. As a player, I want the Ops-style summary (veins held, ore in stock) left out of Profile since the bag drawer and HQ's stored-ore view already cover it, so that Profile doesn't become a second junk drawer.
18. As a player, I want a Notifications app that shows my full notification history, newest first, read-only, so that I can review anything I dismissed or missed as a toast.
19. As a player, I want a single Save/Load app holding all three save slots (save/load/delete each), export, import, and New Game, so that I don't have to hunt across multiple screens for save-related actions.
20. As a player, I want New Game to require an explicit confirmation step before it commits, so that in a game built around Rewind, I can never lose a run to a single accidental tap.

### Notifications

21. As a player, I want at most two notification toasts visible on screen at once, so that a burst of events doesn't flood or overlap my view.
22. As a player, I want overflow notifications to queue and slide in as earlier ones fade out, so that a five-event daily tick drains smoothly instead of being dropped or stacked off-screen.
23. As a player, I want toasts to auto-fade after a few seconds without requiring a tap, so that I'm not forced to manually clear routine notifications.
24. As a player, I want tapping a toast to only dismiss it — never navigate anywhere — so that a mis-tap during a tense moment can't accidentally send me somewhere I didn't mean to go.
25. As a player, I want notification toasts suppressed entirely while I'm in combat, holding in the queue until the fight ends, so that they can never visually clutter or distract from a fight, not just fail to misnavigate.
26. As a player, I want dismissing a toast to only remove it from view, never from my notification history, so that I can still find it later in the Notifications app.
27. As a player, I want my notification history capped at the 50 most recent entries, so that my save file doesn't grow without bound over a long playthrough.
28. As a player, I want a Rewind to also revert my notification history to the state it was in at that point, so that I don't see notifications for events that, after rewinding, never happened.

### Bag drawer

29. As a player, I want to equip and unequip my weapon and device directly from the bag drawer, so that I don't need a separate inventory screen to manage my loadout.
30. As a player, I want to start, attempt to build, and abandon a device directly from the bag drawer, so that all device-crafting actions live in the one place I already use to check my bag.
31. As a player, I want the bag drawer to open from any screen, so that quick-checking or managing my bag never requires backing out to a specific tab first.
32. As a player, I want the bag drawer to fall back to read-only contents plus legal Use buttons during combat and during item-hook events, so that I can't re-optimize my loadout mid-encounter for free.
33. As a player, I want the bag drawer to grow taller and scroll smoothly outside of combat/events, so that a full inventory management view doesn't feel cramped in a small popover.

### Rest, the home-raid trigger, and HQ

34. As a player, I want to rest (end my day and heal) from HQ, so that resting still has a clear, discoverable home once the old flat home screen goes away.
35. As a player, I want a raid on my property to trigger the next time I visit HQ rather than the next time I open my phone, so that the trigger's fiction matches "my base is here, not on my phone."

### Navigation, routing, and save compatibility

36. As a player, loading an old save whose current screen was one of the retired ones (You, Bag, Inventory, Home), I want to land safely on the new app grid rather than being dumped back at the title screen, so that this change never soft-locks an existing save.
37. As a player, winning a raid, I want to land on the phone home screen with the bag drawer already open showing my loot, so that raid rewards surface in the same place I'd check my bag normally.
38. As a player navigating inside an app (e.g. Ticker's axis drill-down), I want that app's own back button to return me one level up within the app, not straight out to the home grid, so that drilling in and backing out feels contained to that app.

## Implementation Decisions

- **Screen/nav topology.** `NavBar` becomes a fixed 3-slot dock: Phone (home button), Map, HQ. `TopBar` is restyled only — no behavior change, still hidden on `title`/`intro`/`map`. `PhoneNav` (existing) gains three new app ids: `profile`, `notifications`, `saveload`. Screens never write `state.phoneNav` directly — only through `PhoneNav`'s existing interface.
- **Retired screen ids:** `you`, `bag` (alias of `inventory.gd`), `inventory`, `home` are deleted. `Nav.go_to("home")` now resolves to the phone app grid. `Main.gd`'s unknown-screen-id fallback, which currently drops to `title`, is changed to map retired ids to `home` instead, so old saves referencing a deleted screen don't soft-lock.
- **Call sites to reroute** off the retired ids: combat's raid win/loss routing (win case lands on phone home with the bag drawer opened via `Bag.open()`), the modal layer's dismiss target, debug-start's initial screen, and every generic back-button-to-home usage project-wide.
- **App grid and tiles.** A reusable tile component (icon + label + badge dot + locked state) backed by an app registry that is roster-agnostic — final app count/roster is a separate, later ticket. Icons are imported `Texture2D` assets with a text-label fallback when the asset is absent, never emoji or the `Icons.draw_*` glyph set (that mechanism stays reserved for map/legend glyphs per M1.5 N6, which this spec supersedes only for app icons specifically). Locked apps use the existing `Icons.draw_padlock` treatment, greyed, in their permanent grid slot — this replaces the current locked-Map hack that overwrites the tab label with hint text; that hint text moves to a tooltip/toast instead.
- **New apps:** Profile (HP/bar, attack range, three skills + XP, read-only equipped weapon/device; explicitly excludes cash/day and the veins-held/ore-in-stock summary), Notifications (read-only log, newest first), Save/Load (three slots with save/load/delete, export, import, confirmation-gated New Game — no destructive action fires in one tap). Profile inherits You's designated future landing spot for reputation (M2), affinities (M3), and Fieldcraft (M2) content.
- **Notification system rework.** `state.notifications` entries become `{ id, text, seen, day }`, capped at 50 most recent, with `seen` replacing deletion-on-tap. Toast rendering rules: max 2 visible at once, queued overflow, auto-fade timers, tap-to-dismiss-only (no deep link), and full suppression while `state.combat` is active — toasts held in queue and drained once combat ends rather than rendering during a fight. All timing/animation state (fade timers, queue advancement) lives only in the `NotificationToast` component — never in `GameState.state` — since state must stay pure data for save/snapshot/Rewind to keep working. Because the log lives in state, it rewinds with everything else by design: a rewound day should not remember notifications for events that no longer happened.
- **Bag drawer promotion.** `BagDrawer` gains everything currently only on the `inventory` screen: equip/unequip weapon, equip/unequip device, device start/build-attempt/abandon. Gating: during combat and during any event card carrying `itemHooks`, the drawer reverts to today's read-only-plus-Use-buttons behavior — management controls hidden. Outside those contexts the drawer becomes a taller, scrollable sheet; it must preserve drag-to-scroll (existing `MOUSE_FILTER_PASS` precedent) rather than swallowing the gesture.
- **Rest and the home-raid trigger relocate to HQ.** HQ's `_ready()` gains a pre-build one-shot check for the home-raid trigger (same pattern the old home screen used: check flags before UI construction, return early if the event starts, since starting it navigates away and frees the node) plus a new Rest action calling the existing `TimeSystem.do_rest()`. This must land before the screen-retirement work removes the old home screen, so there is never a window where the game has no way to rest.
- **Canon amendments** (tracked as their own first ticket, since agents may not redesign canon unilaterally): `REFERENCE.md` §2.2 screen roster updated (remove `you`/`bag`/`inventory`, `home` becomes the app grid, dock is 3 slots); `M1-LONDON.md` D4 updated so Phone is framed as the OS shell with Map/HQ as apps within it rather than three peer places (the addresses/people/bench content split is unchanged, only the nav topology framing changes); `M1-LONDON.md` D4's You-tab entry deleted, its future content redesignated to Profile; `M1-LONDON.md` D4.4's "read-only everywhere except..." rule replaced with "full management outside combat/events, read-only plus Use buttons inside them"; `REFERENCE.md` §3.8's raid-trigger wording changed from "next visit to home screen" to "next visit to HQ."
- **No emoji anywhere in new UI strings** — verified repeated tofu-rendering issue on the exported build (`icons.gd`, `map_canvas.gd`, `ore_glyphs.gd` all document this). Use imported textures, `Icons.draw_*` vectors, or plain ASCII.
- **Layout hazards to design around:** autowrapping `Label`s collapse to one character per line inside an `HBoxContainer` without `SIZE_EXPAND_FILL`/`AUTOWRAP_OFF`; `PanelContainer`/`ProgressBar` default to `MOUSE_FILTER_STOP` and will swallow drag-to-scroll unless handled, per existing documented precedent in this codebase.

## Testing Decisions

Good tests here assert observable state and rendered content — badge presence, tile lock state, toast queue length/visibility, notification log contents after a Rewind — never internal timer or animation implementation details.

- **App grid / tile component:** unit-testable standalone — locked vs. unlocked rendering, badge-dot wiring against the existing `_has_pending_messages()`/`_has_ticker_rumblings()` predicates, text-fallback path when an icon texture is absent.
- **Dock:** 3-slot structure, Phone-as-home-button behavior (navigates from any screen, no-ops on the grid itself), locked-Map tile using the same padlock treatment as the grid.
- **Notification system:** cell/entry cap at 50, `seen` flag transitions, toast max-2-visible and queue-drain behavior, full suppression while `state.combat` is truthy (toast does not render, later drains once combat clears), and a Rewind/snapshot round-trip test confirming the log reverts correctly — mirroring the existing `tests/test_snapshots.gd` pattern used elsewhere for state-purity guarantees.
- **Bag drawer:** gating tests confirming management controls are present outside combat/`itemHooks` events and hidden inside them; equip/unequip and device lifecycle actions produce the same state changes the old `inventory` screen produced.
- **Rest/raid relocation:** one-shot trigger fires on first HQ visit post-condition and never again, mirroring the old `home.gd` one-shot test coverage; Rest action calls `TimeSystem.do_rest()` with identical effects to today.
- **Routing/save migration:** an old save with `currentScreen` set to each retired id (`you`, `bag`, `inventory`, `home`) loads onto the app grid rather than falling back to `title`; raid-win routing lands on phone home with the bag drawer open.
- **Screen-level tests** for Profile and Save/Load, mirroring the existing headless-scene pattern used for other screen tests in this codebase (e.g. the Lab screen tests): correct field rendering, confirm-gate on New Game actually blocking a single-tap commit.

## Out of Scope

- Final app roster and icon count — decided in a later, separate roster ticket; everything here is built roster-agnostic.
- A spoiler audit of which locked apps are safe to show padlocked from day one vs. which should stay fully hidden until unlocked — flagged as a required pre-req for the roster ticket, not resolved here.
- Icon art itself — Richard generates it later; this spec ships the asset contract and text fallback only.
- Wallpaper art for the grid background.
- Toast deep-linking into source apps — considered and rejected (mis-tap risk during combat); the Notifications app is the deliberate-browsing path instead.
- Any change to Messages/Notes/Factions/Ticker content — they are re-hosted as app tiles, not rewritten.
- Safe-area/notch handling for full-bleed layout on notched devices — not addressed by this spec; see Further Notes.

## Further Notes

- **Design review amendment, 2026-08-17:** the original draft framed the no-fake-status-bar decision as avoiding a visual clash with the player's real, adjacent OS status bar. The build was confirmed to run fullscreen/immersive, meaning there is never a real status bar visible on-device to clash with. The decision itself (no fake clock/carrier/battery, full bleed, no bezel) still stands, but on the corrected rationale: it's about not building non-functional decorative system chrome, not about matching something real. Implementers should not scope the status-bar restyle ticket around achieving literal seamlessness with real OS chrome — that seam doesn't exist on this build.
- **Design review amendment, 2026-08-17:** toast suppression during combat was upgraded from "non-deep-linking" (original draft) to full suppression — toasts do not render at all while `state.combat` is active, queuing instead. Reasoning: even a non-navigating toast is still visual noise/occlusion during a fight.
- **Design review flag, 2026-08-17, unresolved:** full-bleed layout with no safe-area handling risks icons or the top grid row landing under a notch/punch-hole camera on some devices. Not resolved in this spec; worth a decision (either explicit safe-area insets or confirmation this doesn't matter for the target device set) before or during the app-grid ticket.
- **Ticket ordering established during design:** canon amendments → icon asset contract/tile component → phone home grid → dock restructure → status bar restyle → Profile app → Save/Load app → notification log/toast rework → Notifications app → bag drawer promotion → Rest/raid relocation to HQ (must land before retirement) → screen retirement and routing cleanup (last, depends on nearly everything above). Ticket breakdown into `.scratch/11-phone-os-shell/issues/` should follow this order.
- Prose for new UI strings (app names, lock messages, confirm dialogs, empty states) needs `PROSE-REVIEW` against `docs/CONTENT-GUIDE.md`, carried into whichever ticket writes the actual copy.
