# 01 — Consolidate phone-tab assets

**What to build:** Phone-tab wallpaper, supplied source artwork, and runtime launcher icons have one phone-owned asset location. The launcher continues to render every app icon and the home wallpaper after the move.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `assets/phone/`, `assets/icons/apps/`, `tools/make_phone_app_icons.ps1`, `scenes/components/app_tile.gd`, `autoload/GameData.gd`, `data/phone_home.json`, `tests/test_phone_device_shell.gd`, `docs/ui-vision.md`, `docs/REFERENCE.md` § “Phone home”, `docs/adr/0003-app-icon-asset-contract.md`, `CODEMAP.md`.

- [ ] Move or regenerate phone-tab artwork so no phone-tab asset remains under the general icon directory; remove obsolete duplicate source artwork only after confirming it is unused.
- [ ] Update generation tooling, runtime paths, data validation, tests, architecture/UI documentation, and CODEMAP to the unified asset contract.
- [ ] Run Godot 4.7 checks and the full headless test suite; verify every phone home launcher icon and wallpaper loads with no missing-resource errors.
