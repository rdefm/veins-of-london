# App icon asset contract

11-phone-os-shell ticket 02 needs a fixed contract for where app-tile icon
art lives and how it's named, so the tile component (`scenes/components/app_tile.gd`)
and every future ticket that adds an app (roster ticket, Profile, Save/Load,
Notifications, dock restructure) agree on the same path without re-deciding
it per app. No icon art exists yet — Richard generates it in a later ticket
(11-phone-os-shell spec, Out of Scope) — so this also fixes the contract for
"art hasn't landed" being a normal, non-error state.

**Decisions:**
- **Path:** `res://assets/icons/apps/<app_id>.png`, one file per app.
- **Naming:** `<app_id>` is the exact id the app is addressed by everywhere
  else it's wired up, lowercase, no separators — never a second, icon-only
  naming scheme. `PhoneNav.APPS` already has four of these live
  (`"messages"`, `"notes"`, `"factions"`, `"ticker"`), and the dock adds
  `"map"`/`"hq"`. The 11-phone-os-shell spec's Implementation Decisions
  commits `PhoneNav` to gaining three more — `"profile"`, `"notifications"`,
  `"saveload"` — but those apps aren't built yet, so those three ids aren't
  live in code as of this ticket; whichever ticket builds each app (Profile/
  Notifications/Save-Load) is what actually wires its id into `PhoneNav.APPS`,
  and should reuse the id the spec already names rather than minting a new
  one.
- **Format/size:** PNG with alpha, square, 128×128px source. The tile
  component renders icons inside a 56×56 frame; 128px gives headroom for
  higher-density phone screens without shipping oversized source art.
  Import as a plain 2D `Texture2D` (Godot's default PNG import) — Filter on,
  Mipmaps off (it's flat UI art at a fixed small size, never seen at a
  distance or minified in 3D, so mipmaps just cost import time/disk for no
  benefit).
- **Loading:** `AppTile.load_icon(app_id)` is the one place that resolves
  `app_id -> Texture2D`, via `ResourceLoader.exists()` before `load()`. A
  missing file returns `null` rather than erroring — the tile falls back to
  rendering the app's own label text inside the icon frame instead of
  failing to render (ticket 02's explicit acceptance check). Callers should
  never build the path themselves or `load()` an icon directly.
- **Never emoji, never `Icons.draw_*`** for app icons — `Icons.draw_*` stays
  reserved for map/legend glyphs per M1.5 N6; this contract is additive to
  that reservation, not a change to it. The one exception, called out
  explicitly in the 11-phone-os-shell spec, is the locked-tile padlock
  overlay, which does reuse `Icons.draw_padlock` — that's a lock-state
  indicator drawn on top of the tile, not the app's own icon art.

**Status:** accepted (2026-08-17, 11-phone-os-shell ticket 02).
