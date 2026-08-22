# 55 — Fix home-raid victory text

**What to build:** The combat screen's victory label (`scenes/screens/combat.gd:96-99`) picks between `"✅ They've legged it"` (for `Combat.NON_LETHAL_MUGGING_CONTEXTS`, `combat.gd:26` — mugging contexts only) and a generic `"✅ Vein secured"` for every other context — including `CONTEXT_HOME_RAID` (`data/events/home_raid_intro.json:9` → `Combat.start_home_raid_combat()`, `combat.gd:164-174`). Winning the intro home-defense fight therefore shows "Vein secured" / "They go down. Vein is yours." (`combat.gd:265`, `:493`) even though no vein is involved — it's the player's own flat. Add a home-raid-specific victory label/log line: **"Flat secured"** / **"They're gone."**

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `CONTEXT_HOME_RAID` gets its own victory label ("Flat secured") and log line ("They're gone.") distinct from both the mugging and generic-vein text, in `scenes/screens/combat.gd` and `systems/combat.gd` (`:265`, `:493`).
- [ ] Confirm other raid/defend contexts (`CONTEXT_RAID`, `CONTEXT_EVENT_RAID`, `CONTEXT_DEFEND_VEIN`) keep the existing "Vein secured" text, since those genuinely are about a vein.
- [ ] Test updated/added confirming `CONTEXT_HOME_RAID` produces the new text, and other contexts are unaffected.
- [ ] Manual check noted for the human: replay the intro home-raid fight and confirm the win screen says "Flat secured" / "They're gone."
