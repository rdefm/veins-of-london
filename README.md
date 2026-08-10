# veins-of-london

## Mobile export (Android)

`export_presets.cfg` has an "Android" debug preset (`build/vein.apk`, arm64-v8a, non-Gradle build), verified working: `godot --headless --export-debug Android build/vein.apk` produces an installable, offline-playable APK (no network calls anywhere in the codebase, so it needs nothing beyond what's bundled).

**One-time machine setup** (per-machine, not per-checkout):

1. Android SDK: `platform-tools` + `build-tools;34.0.0`, installed via the `cmdline-tools` `sdkmanager` (full Android Studio not required).
2. A JDK — Godot's `sdkmanager` needs **17+** (an old JRE 8 will fail with `UnsupportedClassVersionError`); Temurin 17 works.
3. Godot 4.4 Android export templates (`android_debug.apk`, `android_release.apk`) in `%APPDATA%\Godot\export_templates\4.4.stable\` — from the editor's Manage Export Templates dialog, or the `Godot_v4.4-stable_export_templates.tpz` on the [godotengine/godot 4.4-stable release](https://github.com/godotengine/godot/releases/tag/4.4-stable).
4. A debug keystore, and Editor Settings → Export → Android pointed at all three (`android_sdk_path`, `java_sdk_path`, `debug_keystore`).

**Gotcha:** the export fails with `Cannot export project with preset "Android" due to configuration errors:` and **no further detail** if `project.godot` is missing `rendering/textures/vram_compression/import_etc2_astc=true` — a Godot engine bug (`has_valid_project_configuration` sets `valid=false` without ever appending error text for this one check). Normally the editor sets this the first time you click through its "enable ETC2/ASTC?" prompt when adding a mobile export preset; since this preset was hand-authored, that never happened. It's set in `project.godot` now — if it ever reverts, that silent failure is why.

**Building + installing:**

```
godot --headless --export-debug Android build/vein.apk
adb install build/vein.apk
```

Or skip `adb`: copy `build/vein.apk` to the phone (cloud drive, USB, email) and tap it to sideload — enable "install unknown apps" for whatever app opens it.

`scripts/setup_godot.sh` gets you the headless Godot *binary*; it does not install export templates or the Android SDK.