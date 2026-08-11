# 09 — App opens in landscape despite the portrait project setting

**What to build:** Installed on-device (Android), the app currently opens in landscape and can't be rotated to portrait, even though `project.godot` already sets `window/handheld/orientation="portrait"` and a portrait viewport (390×844), and this was confirmed still broken on a fresh rebuild/reinstall done the night before this ticket was written. No conflicting orientation override was found anywhere in `export_presets.cfg` or the rest of the repo — this needs on-device/build-pipeline investigation, not a blind code change.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Root-cause why the exported build doesn't honour `window/handheld/orientation="portrait"` — check the actual `screenOrientation` attribute in the exported `AndroidManifest.xml`, and whether the non-gradle export path (`gradle_build/use_gradle_build=false` in `export_presets.cfg`) is correctly applying this project setting.
- [ ] Fix whatever the root cause turns out to be so a fresh build opens, and stays, in portrait on-device — no rotation to landscape possible.
- [ ] Once portrait is confirmed on-device, re-test the "Something woke you up" new-game event (`data/events/home_raid_intro.json`) specifically: the Continue button was previously unreachable (suspected to be this landscape bug cutting off the bottom-anchored action bar in `scenes/screens/event.gd`). If the Continue button is now reachable, no further action needed. If it's still unreachable in confirmed portrait, file a new separate ticket for it — don't try to fix it under this one.
