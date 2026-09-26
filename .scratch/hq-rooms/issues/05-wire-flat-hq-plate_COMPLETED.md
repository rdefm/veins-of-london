# 05 — Wire flat HQ plate

**What to build:** A player whose home tier is **flat** sees `assets/hq/flat_room.png` as the HQ room view, with no placeholder boxes. Every zone the human traced opens its menu, taps outside the traced shapes do nothing, and zones the human left unset are absent. The rest caption sits legibly on the bed art.

**Blocked by:** 01, 02

**Status:** done

- [x] `rooms.flat` exists in `data/hq_visuals.json`, points at `assets/hq/flat_room.png`, and passes the data check
- [x] Every flat region has `placeholder: false`
- [x] A flat-tier player gets the flat plate (test)
- [x] Each traced zone routes to its menu (test per zone)
- [x] Security traced; raid no longer relabels the door (ticket 02), no installedImage on flat
- [x] Other tiers are unchanged
- [x] On-device check block for the human in the report
