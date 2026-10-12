# 01 — Register shell and home

**What to build:** Opening The Register shows the mockup's distinct dark app: a five-node masthead and a compact, flat directory of the player's five faction relationships. The shared phone frame and other apps retain their current styling.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/factions_app.gd`, `scenes/screens/phone.gd`, `scenes/components/contact_cards.gd`, `scenes/components/phone_device_shell.gd`, `scenes/components/ui.gd`, `data/palette.json`, `docs/ui-vision.md`, `tests/test_phone_apps.gd`, `CODEMAP.md`; visual reference: `.scratch/factions-app-redesign/mockup.html`.

- [ ] Inside the existing device frame, all Register pages use a warm graphite canvas, readable light and muted text, fine dividers, oxide-orange accents and the mockup's spacing. The masthead has the five-node connected mark, uppercase **THE REGISTER**, **LONDON POWER INDEX**, and an orange bottom rule. App-specific styling survives the shared phone styling pass without recolouring other apps.
- [ ] Home has the mockup's **YOUR POSITION / Your standing** hierarchy. Its five faction rows are flat and divided, not separate rounded cards. Each shows a circular faction dot and name, stored stance and signed relation on the top line; live alert, centred neutral meter with zero marker and endpoint dot, and orange chevron on the lower line. The full row remains tappable.
- [ ] The **LONDON** routes are flat two-line rows with short explanatory subtitles and chevrons, in the mockup's order: London politics, then Market shares. Home fits and scrolls cleanly at phone and narrow widths without clipped labels or touch targets.
- [ ] Back routes and all live relationship, stance and alert reads remain as implemented. Automated checks cover the five rows and navigation; on-device comparison includes a home screenshot beside the mockup. Godot 4.7 syntax and full tests pass. Flag any new prose with `PROSE-REVIEW:`.
