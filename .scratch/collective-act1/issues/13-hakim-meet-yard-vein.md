# 13 — Hakim meet / yard vein (S11)

**What to build:** Taking on Hakim's failing yard vein to work while he can't.
Full detail in `.scratch/collective-act1/spec.md` §6.11 — read it before
starting. Card text is `PROSE-REVIEW:` draft.

**Blocked by:** 08, 02.

**Status:** ready-for-agent

- [ ] `col_a1_hakim_meet` is reachable as a Whitechapel map pin gated on
      `colA1HubReached` / not `colA1HakimMet`.
- [ ] `on_complete` creates an emotion vein at `growth: 18` (`sparse` band),
      tier `fair`, in `state.player.veins` via `grant_contact_vein`, storing
      its id at `state.collective.hakimVeinId`, and sets `colA1HakimMet`.
- [ ] `col_a1_hakim_rescue` (`vein_growth_above`, `veinIdStatePath:
      "collective.hakimVeinId"`, `threshold: 60`) is active from here — it was
      already activated at S4 (ticket 08), this ticket is what gives it
      something real to read.
- [ ] The balance note in §6.11 (~9-10 blocks / 3-4 days to reach growth 60,
      no collapse risk in that window) holds given the vein's starting growth
      and drift — don't start it lower than 18.
