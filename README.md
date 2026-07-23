# veins-of-london

## Mobile export (Android)

`export_presets.cfg` has an "Android" debug preset (`build/vein.apk`, arm64-v8a, non-Gradle build) already checked in. It was hand-authored against the Godot 4.4 export-preset schema — this sandbox has no network access to `godotengine/godot`'s GitHub releases (blocked by the session's GitHub source scope), so neither the Godot editor nor export templates were reachable here to generate or verify it. Treat it as a starting point, not a verified artifact.

**HUMAN-ACTION — building the APK:**

1. Install the Godot 4.4 Android export templates. Easiest path: open the project in the Godot 4.4 editor once (Editor → Manage Export Templates → Download and Install), or download `Godot_v4.4-stable_export_templates.tpz` from the [godotengine/godot 4.4-stable release](https://github.com/godotengine/godot/releases/tag/4.4-stable) and install it via the same dialog.
2. Confirm the Android SDK / build tools Godot needs are installed (Editor → Editor Settings → Export → Android — `adb`, `jarsigner`, and either the Gradle build tools or a debug keystore, depending on the preset's `gradle_build/use_gradle_build` setting).
3. Open the project in the editor once and check Project → Export → "Android" — this both confirms `export_presets.cfg` parsed correctly and lets you fix anything the hand-authored version got wrong (package name, SDK versions, icons) before building.
4. From the project root:
   ```
   godot --headless --export-debug Android build/vein.apk
   ```
5. Install/test: `adb install build/vein.apk`, or sideload onto a device.

`scripts/setup_godot.sh` gets you the headless Godot *binary* for steps 4+; it does not install export templates or the Android SDK — those are step 1-2, and need the full editor or manual template installation.