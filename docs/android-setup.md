# Android setup — build & install Vein on your phone

One-time machine setup + build steps to turn this project into an installable APK on an Android phone. Written for Windows/PowerShell. Everything below already ran once on this machine — this doc is so it can be repeated (new machine, reinstall, etc.) without re-deriving it.

Related: `README.md` § Mobile export (Android) for the short version and the ETC2/ASTC gotcha.

## 0. What you end up with

A debug-signed `build/vein.apk` (~26MB) you sideload onto your phone. Fully offline — the game has no network calls, everything is bundled into the APK.

## 1. Install a JDK (17+)

Godot's `sdkmanager` needs Java 17+; an old JRE 8 fails with `UnsupportedClassVersionError`. Download Temurin 17 and unzip it locally (no installer/admin needed):

```powershell
$ProgressPreference = 'SilentlyContinue'
$tools = "C:\Users\Richard\AppData\Local\dev-tools"
New-Item -ItemType Directory -Force -Path $tools | Out-Null
Invoke-WebRequest -Uri "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse" -OutFile "$env:TEMP\jdk17.zip" -UseBasicParsing
Expand-Archive -Path "$env:TEMP\jdk17.zip" -DestinationPath $tools -Force
Get-ChildItem $tools   # note the exact jdk-17.x.y+z folder name
```

## 2. Install the Android SDK (cmdline-tools only — no Android Studio needed)

```powershell
$ProgressPreference = 'SilentlyContinue'
$sdk = "C:\Users\Richard\AppData\Local\Android\Sdk"
New-Item -ItemType Directory -Force -Path "$sdk\cmdline-tools" | Out-Null
Invoke-WebRequest -Uri "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" -OutFile "$env:TEMP\cmdline-tools.zip" -UseBasicParsing
Expand-Archive -Path "$env:TEMP\cmdline-tools.zip" -DestinationPath "$env:TEMP\cmdline-tools-extract" -Force
if (Test-Path "$sdk\cmdline-tools\latest") { Remove-Item "$sdk\cmdline-tools\latest" -Recurse -Force }
Move-Item "$env:TEMP\cmdline-tools-extract\cmdline-tools" "$sdk\cmdline-tools\latest"
```

(Check [Google's cmdline-tools download page](https://developer.android.com/studio#command-tools) for the current filename if that URL 404s — the build number changes over time.)

Accept the SDK licenses (needs to be piped — `sdkmanager` prompts `y/N` per license):

```powershell
$env:JAVA_HOME = "C:\Users\Richard\AppData\Local\dev-tools\jdk-17.0.20+8"   # match your actual folder from step 1
$sdk = "C:\Users\Richard\AppData\Local\Android\Sdk"
$yesFile = "$env:TEMP\yes_input.txt"
(1..30 | ForEach-Object { "y" }) | Set-Content -Path $yesFile -Encoding ASCII
cmd /c "`"$sdk\cmdline-tools\latest\bin\sdkmanager.bat`" --sdk_root=`"$sdk`" --licenses < `"$yesFile`""
```

Install platform-tools (`adb`) and build-tools (`zipalign`, `apksigner`):

```powershell
& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="$sdk" "platform-tools" "build-tools;34.0.0"
```

## 3. Generate a debug keystore

```powershell
$keytool = "C:\Users\Richard\AppData\Local\dev-tools\jdk-17.0.20+8\bin\keytool.exe"   # match your JDK folder
$ksDir = "C:\Users\Richard\AppData\Roaming\Godot\keystores"
New-Item -ItemType Directory -Force -Path $ksDir | Out-Null
& $keytool -genkeypair -v -keystore "$ksDir\debug.keystore" -storepass android `
  -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 `
  -dname "CN=Android Debug,O=Android,C=US"
```

## 4. Install Godot's Android export templates

Download the templates archive matching your Godot version (this project targets 4.4-stable) and pull out just the Android pieces:

```powershell
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz" -OutFile "$env:TEMP\godot_templates.tpz" -UseBasicParsing
Copy-Item "$env:TEMP\godot_templates.tpz" "$env:TEMP\godot_templates.zip" -Force   # .tpz is just a renamed .zip
Expand-Archive -Path "$env:TEMP\godot_templates.zip" -DestinationPath "$env:TEMP\godot_templates_extract" -Force

$destDir = "$env:APPDATA\Godot\export_templates\4.4.stable"
New-Item -ItemType Directory -Force -Path $destDir | Out-Null
Copy-Item "$env:TEMP\godot_templates_extract\templates\android_debug.apk" "$destDir\android_debug.apk" -Force
Copy-Item "$env:TEMP\godot_templates_extract\templates\android_release.apk" "$destDir\android_release.apk" -Force
```

This is a ~1.2GB download (it bundles templates for every platform, not just Android) — expect it to take a few minutes.

Clean up afterwards if you want the disk space back:

```powershell
Remove-Item "$env:TEMP\godot_templates.tpz","$env:TEMP\godot_templates.zip","$env:TEMP\cmdline-tools.zip","$env:TEMP\jdk17.zip" -ErrorAction SilentlyContinue
Remove-Item "$env:TEMP\godot_templates_extract","$env:TEMP\cmdline-tools-extract" -Recurse -Force -ErrorAction SilentlyContinue
```

## 5. Point Godot's editor settings at everything

Godot reads these from `%APPDATA%\Godot\editor_settings-4.4.tres` under `[resource]`. Either set them via the editor GUI (Editor → Editor Settings → Export → Android) or edit the file directly:

```
export/android/debug_keystore = "C:/Users/Richard/AppData/Roaming/Godot/keystores/debug.keystore"
export/android/debug_keystore_pass = "android"
export/android/java_sdk_path = "C:/Users/Richard/AppData/Local/dev-tools/jdk-17.0.20+8"
export/android/android_sdk_path = "C:/Users/Richard/AppData/Local/Android/Sdk"
```

(Match the JDK folder name to whatever step 1 actually downloaded.)

## 6. The silent-failure gotcha

`project.godot` needs `rendering/textures/vram_compression/import_etc2_astc=true`. Without it, the export fails with:

```
ERROR: Cannot export project with preset "Android" due to configuration errors:
```

...and **no further detail** — a genuine Godot engine bug (`has_valid_project_configuration` sets `valid = false` without ever appending error text for this specific check). Normally the editor sets this the first time you click through its "enable ETC2/ASTC?" prompt when adding a mobile export preset. It's already set in this repo's `project.godot` — only relevant if it's ever missing again and the export fails with that unhelpful message.

## 7. Build the APK

From the project root:

```powershell
.\Godot_v4.4-stable_win64_console.exe --headless --export-debug "Android" "build\vein.apk"
```

(Or `godot --headless --export-debug Android build/vein.apk` if `godot` is on PATH.) Output: `build\vein.apk`.

## 8. Install it on your phone

**Option A — USB + adb:**

1. On the phone: Settings → About phone → tap "Build number" 7 times to unlock Developer Options.
2. Settings → Developer Options → enable "USB debugging".
3. Plug the phone into the PC via USB, accept the "Allow USB debugging?" prompt on the phone.
4. ```powershell
   C:\Users\Richard\AppData\Local\Android\Sdk\platform-tools\adb.exe devices   # confirm the phone shows up
   C:\Users\Richard\AppData\Local\Android\Sdk\platform-tools\adb.exe install build\vein.apk
   ```

**Option B — sideload without a cable:**

1. Copy `build\vein.apk` to the phone — email it to yourself, drop it in a cloud drive folder (Google Drive/Dropbox/OneDrive), or AirDrop-equivalent.
2. On the phone, open the file from wherever you saved it.
3. Android will prompt to allow installs from that app ("install unknown apps") — allow it, then tap Install.

Either way: the app installs as **Vein** (package `com.veinsoflondon.vein`), works fully offline, no further setup needed.

## Re-building after code changes

Only step 7 needs repeating — steps 1–6 are one-time machine setup.
