# 09 — Des's weather beats (S5–S6)

**What to build:** Two location-agnostic "Firm as weather" beats that fire
during prospecting itself, pre-empting (not stacking with) the district deck
draw — plus the point where the method log silently opens. Full detail in
`.scratch/collective-act1/spec.md` §6.5, §6.6, §5.7, §10.4 — read it before
starting. Card text is `PROSE-REVIEW:` draft.

**Blocked by:** 08, 02.

**Status:** ready-for-agent

- [ ] The prospect-vs-deck-draw trigger hook checks the story beat first and,
      if it fires, gives a genuine early return — the deck's RNG roll is
      provably not consumed, asserted by a test (§10.4).
- [ ] S5 (`col_a1_firm_skirmish`) fires on the **first** qualifying
      `Sites.prospect()` completion after `colA1DesThreadActive`; S6
      (`col_a1_firm_intimidation`) fires on the completion that produces the
      **second** qualifying site for `col_a1_des_sites`. Both are location-
      agnostic (any district).
- [ ] S6's three choices ("Back off" / "Hold your ground" / "Tell them where
      to go") all leave both patches with the player regardless of choice;
      only `methodLog.firmFirstContact` (and, for "fought," a
      `start_street_mugging`) differ — no relation change, no retaliation from
      any branch.
- [ ] `state.methodLog` is added to `GameState.new_game_state()` as `{}` and
      is restored by `Events.rewind()` like any other state (this is the
      deliberate decision closing
      `plans/COLLECTIVE-QUESTLINE.md` §8.3 — mark it resolved).
