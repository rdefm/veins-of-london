# 10 — Gym: Flip Reverse (Arnie)

**What to build:** Prologue step 5. Archie brings you to his mate's gym, "just in case". 2–3 intro cards, then **one guided spar** (practice scripted fight) with one lesson per round via coach marks: R1 Guard (read the intent, block), R2 Feint → Strike, R3 Stun on an Open target. Leg it gets one line. Introduce the gym's free Rewind ("House rules."). Then a **demo fight**: Arnie spars Archie for 1–2 auto-resolving rounds showing Feint L5 (autoguard → retaliate), with one line on levels. Exit: `gymUnlocked`, 3 free sessions intact.

**Arnie** (`.scratch/prologue-act/spec.md`; `docs/story-restructure.md` "The gym owner"): Archie's mate. A belly with muscle under it; he calls it a "dad bod", his waistline says otherwise. The calc fighters' gym under a railway arch is **Flip Reverse**, after the Blazing Squad song: he was a big fan in his youth and proudly recalls getting into a punch-up with some of the band. The "Flip" has fallen off the sign, so it reads "Reverse". The player should trust and like him. **Do not** hint that he's ex-Firm or trained Nick, and don't reveal his real name (Reginald).

Also update the existing spar lines and the gym map-pin modal copy to fit Flip Reverse. Placeholder sprite for Arnie.

**Prose rules:** follow `docs/writing-guide.md` (structure, humour, characters, audit) and `docs/CONTENT-GUIDE.md`. The sign and the band story land once each, in character. Run the writing-guide audit before handing in. Flag every new/changed prose file with `PROSE-REVIEW:`.

**Blocked by:** 03 — Practice scripted fights; 05 — Prologue chain skeleton.

**Relevant files:** the beat 5 placeholder event, `data/combat_rounds.json` (`spar` lines, coach hints), `scenes/modals/gym_spar_modal.gd`, `systems/sparring.gd`, `tests/test_demo_fight.gd` (demo script shape). REFERENCE §3.7b "Scripted fights", "Demo fights", "Coach marks", "Spar". `docs/story-restructure.md` Prologue step 5.

**Status:** ready-for-agent

- [ ] Event runs headless: guided spar (win path), demo, `gymUnlocked` set, free sessions intact.
- [ ] Each round's lesson is achievable with the allowed moves and fixed partner plans.
- [ ] No ex-Firm / Nick / Reginald hints.
- [ ] Writing-guide audit done; `PROSE-REVIEW:` flagged.
- [ ] Human on-device: coach marks readable, demo pacing, Arnie lands as likeable.
