# 11 — Rebrand The Ticker launcher icon

**What to build:** The Ticker tile in the Phone tab shows the existing rising bars and arrow icon in The Ticker's menu brand colours. Preserve the icon's current rounded square, mark geometry, and size; replace the green treatment with the menu's burgundy (`#9c2340`) and the light mark with its paper colour (`#f1eae3`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `tools/make_phone_app_icons.ps1`; `assets/phone/icons/ticker.png`; `scenes/components/app_tile.gd`; `scenes/screens/phone.gd`; `scenes/phone_apps/ticker_app.gd`; `docs/adr/0003-app-icon-asset-contract.md`; `docs/ui-vision.md` §10 Family 2, The Ticker exception; `.scratch/ticker-revamp/ticker-concept.html`.

- [ ] The Phone tab's Ticker tile uses a 128×128 PNG with alpha at the existing app-icon path and still reads as the same rising bars and arrow icon at tile size.
- [ ] Its background uses The Ticker's burgundy and its mark uses the menu's paper colour; no green remains in this icon.
- [ ] Regenerating phone icons preserves the new Ticker colours; other app icons remain unchanged.
- [ ] Godot 4.7 headless checks pass, and on-device visual QA confirms the icon is legible beside other Phone tiles and matches The Ticker menu branding.
