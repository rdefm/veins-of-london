# Phone tab refresh — diegetic smartphone home

## Goal

Refactor the Phone tab home from a generic menu/grid into a believable contemporary London smartphone. The absurdity comes from the installed apps and their content, not fantasy-themed phone chrome. Preserve all game mechanics and the external amber Tube-display HUD plus Phone / Map / HQ navigation.

## Visual authority

[`phone_tab_mockup.png`](phone_tab_mockup.png) is the primary composition reference for the device frame, status bar, home widget, four-column launcher, icon proportions, badges, wallpaper treatment, and three-icon dock. Written decisions below override the image where they differ.

The user-supplied source icons under `assets/phone/` are authoritative starting artwork for the corresponding apps. Final runtime icons still follow `docs/adr/0003-app-icon-asset-contract.md`: square 128×128 alpha PNGs under `assets/icons/apps/<app_id>.png`.

[`assets/phone/phone-wallpaper.jpg`](../../assets/phone/phone-wallpaper.jpg) is the supplied, approved runtime wallpaper. Use this exact image for the phone home background; fit/crop it responsively inside the rounded display, but do not regenerate or replace it.

## Locked decisions

- The simulated device sits inside a dark rounded smartphone frame. It has a conventional internal status bar: decorative time, cellular signal, Wi-Fi, battery glyph, and percentage.
- The status/date/weather values are fixed presentation matching the mockup (`08:14`, `Tue, 14 May`, cloudy `12°C`, `London`, `87%`). They do not add calendar, weather, connectivity, or battery mechanics; do not enter `GameState`; do not query the host clock or network. Store player-facing copy/data in JSON rather than burying it in UI code.
- The top home widget includes the exact understated line: `Same city. Different rules.`
- The old `Phone` page heading is removed from the home view.
- The supplied `assets/phone/phone-wallpaper.jpg` fills the simulated screen behind home UI. It is atmospheric and recognisably London, with no Underground roundel, graffiti, lettering, signs that read as buttons, or other UI-like focal elements competing with icons.
- Home apps use a four-column grid. Main order is:
  1. Alarms
  2. Notes
  3. BizBrief
  4. The Ticker
  5. Factions
  6. Reynard's
  7. Harrow's
  8. My File (existing internal id `profile`)
  9. Contacts
  10. TfL (existing internal id `vfl`; current Map gate/routing stays intact)
  11. Notifications
  12. Save/Load
- Debug remains an app under its existing rule: absent on normal games and appended after Save/Load only when `flags.debugStartUsed` is true.
- Every launcher icon has the same rendered dimensions, corner radius, centred label typography, and badge treatment. System apps look mundane and contemporary. Fictional apps may retain stronger branding, especially Reynard's and Harrow's.
- Badges are red numeric counts, hidden at zero, with a consistent capped overflow treatment. Live sources are pending alarms, BizBrief attention items, Ticker rumblings, unseen notifications, and total unread Messages.
- The home dock is a translucent/dark rounded surface with exactly three symmetrically-spaced apps: Phone, Messages, Settings. Messages carries its unread badge. Messages and Settings never appear in the main grid.
- Phone uses internal app id `dialer` and opens a simple recent-calls placeholder without introducing call mechanics. Messages opens a conversation index and then the existing thread views. Settings uses internal app id `settings` and owns the existing reduced-motion and alarm-vibration preferences, moved out of My File/Profile.
- Save/Load and Debug remain apps for now. Their current functionality is not redesigned by this refresh.
- The device frame/status bar remains around app content. Wallpaper, home widget, launcher grid, and dock appear only on the home view; opened apps retain the existing dark Phone-OS content surface and navigation.
- The persistent amber pixel-art top board is unchanged. The external Phone / Map / HQ navigation is unchanged. They remain game UI outside the simulated device.

## Non-goals

- No game-calendar, live weather, telephony, connectivity, or battery simulation.
- No mechanics, formulas, state schema, save-format, Map gate, app-content, top-board, or external nav redesign.
- No duplicate Messages or Settings tile in the main launcher.
- No deletion or functional redesign of Save/Load or Debug.
- No Underground roundel or fantasy/magical ornament in phone chrome.

## Implementation order

1. Canon/spec alignment.
2. Device shell, wallpaper, status bar, and home widget.
3. Four-column main launcher, icon set, roster, and numeric badges.
4. Phone / Messages / Settings dock and app routing.

## Completion contract

- Each implementation ticket is independently headless-testable and demonstrable.
- After every `.gd` edit, run the configured Godot 4.7 console binary with `scripts/check_runner.gd` for that file.
- Run `scripts/run_tests.sh` before completing each ticket.
- Update `CODEMAP.md` whenever ownership/files under `systems/`, `scenes/`, `autoload/`, or `data/` change.
- Human phone QA is required for frame proportions, wallpaper competition, four-column fit, label/badge legibility, dock symmetry, touch targets, and separation from the outer HUD/nav.
