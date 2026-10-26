# Arnie tutorial — transcript (live data)

Source: `data/events/gym.json` (event id `gym`), `data/combat_rounds.json` (`spar.lines`, gym-only). Play order. Bracketed ids = card key / field path for mapping rewrites back. Event is linear: no branching; each choice card has a single choice.

Mechanics-only fields (stats, plans, seeds) omitted; prose only.

---

## c1 — narration `[gym.cards.c1]`
Label: *Whitechapel — under a railway arch*

> A train goes over and the whole arch hums. The sign above the roller door says REVERSE, with a clean pale patch in front of it where another word used to be.

## c2 — Archie `[c2]`
> "Gym. Mate of mine runs it." He ducks under the shutter. "Last night you stood there looking like a pain to fight. Time to be one. Don't ask about the sign."

## c3 — narration `[c3]`
> Arnie is taping his knuckles: wide as the door, soft round the middle, forearms that don't match. "Dad bod," he says, before you've said anything. "Don't let it fool you."

## c4 — Arnie `[c4]`
> "Flip Reverse, it's called. After the Blazing Squad song. Flip fell off in a storm." He's grinning. "I once had a punch-up with two of the band outside a chippy. Best night of my life. Lost, mind."

## c5 — choice `[c5]`
> Arnie waves Archie onto the mats. Archie takes his jacket off and folds it. "Watch this first," Arnie says. "I'll talk you through it."

Choice `[c5.choices.watch]`: **Watch** (result_text empty)

### Demo fight: "Sparring" — Arnie vs Archie `[c5.choices.watch.effects[0].script]` (op `start_demo_fight`, resumes at c6)

Fight label: `Sparring`
Intro line `[script.intro[0]]`:
> Arnie squares up to Archie.

Coach notes (spoken by Arnie as Archie fights; `[script.coach.notes.<round>.<trigger>]`). Where a trigger has two lines, they alternate/vary on repeat (array order).

**Round 1** `[notes.1]`
- `other.chip` (1st): "He starts behind his guard, so my first one only chips him."
- `other.chip` (2nd): "That's all a punch gets through a guard. A chip."
- `other.guard`: "He's covered up again. Fine. That's what the Feint's for."
- `other.feint`: "At level one, that's all a Feint does: his guard drops. At five, everything I land while it's down hits harder."
- `other.autoguard`: "I've just Feinted, so I'm Open. At five my guard comes up by itself anyway. At level one I'd have eaten that."
- `other.retaliate`: "And at five I sometimes get one back for free. Doesn't cost me a turn."
- `other.hit` (1st): "Straight in. He's still Open from the Feint."
- `other.hit` (2nd): "That's the Feint's extra on top. Keep him Open, keep hitting."

**Round 2** `[notes.2]`
- `other.hit` (1st): "He never got his guard back, so that lands in full."
- `other.hit` (2nd): "No free one back that time. It only comes off now and then. So I just hit him."
- `other.guard`: "Guard's back up. That's him reset."
- `other.feint`: "So I Feint again, and it's gone."
- `other.autoguard`: "Same again. My guard's up before he's thought about it."
- `other.chip`: "One point. He'd do better saving his breath."

(Note: coach lines are in Arnie-as-narrator voice but written first-person "I/my" as if Archie is speaking? — they read as Archie's POV ("my first one", "my guard"). Check speaker attribution when rewriting.)

## c6 — Arnie `[c6]`
> He throws Archie a towel. "Same Feint you've got. Just more hours on it. Your go."

## c7 — Arnie `[c7]`
> "House rules. There's a Rewind on the shelf, free, as many as you like. Go wrong, break it, go again. Walk out and I wind you back to the morning anyway. Leg it whenever you want. Nobody's marking you."

## c8 — choice `[c8]`
> Arnie tosses you a pair of gloves. They're your size. Nobody asked him for your size.

Choice `[c8.choices.glovesOn]`: **Gloves on** (result_text empty)

### Tutorial fight (practice, Arnie vs player) `[c8.choices.glovesOn.effects[0].script]` (op `start_scripted_fight`, resumes at c9)

Intro line `[script.intro[0]]`:
> Mats down. Arnie rolls his shoulders.

Coach lessons (shown as the instruction at the start of each round; player is limited to the listed moves) `[script.coach.lessons.<round>]`

**Round 1** (allowed: Guard)
> His intent says Strike, twice. Pick Guard: while you're Guarded, a punch only chips you.

**Round 2** (allowed: Feint, Strike)
> He's covering up, so a Strike would only chip him. Feint to knock his guard open, then Strike for the full hit.

**Round 3** (allowed: Stun, Strike)
> He swings first, and swinging leaves him Open. Stun him while he's Open to take his next action, then Strike.

Coach notes (reactive, after events in the round) `[script.coach.notes.<round>.<trigger>]`

**Round 1** `[notes.1]`
- `other.chip`: Your guard took most of that. Guarded, you only lose a chip.
- `self.guard`: Still Guarded for whatever he throws next.

**Round 2** `[notes.2]`
- `other.guard`: He's Guarded. Hit him now and you'd only chip him.
- `self.feint`: He bit. He's Open, and his next Guard won't hold.
- `self.hit`: Open, so it landed in full.

**Round 3** `[notes.3]`
- `other.hit`: You were Open after your last Strike, so that one landed in full.
- `self.stun`: Stunned. He loses his next action.
- `other.lost`: That was his Guard gone. He's still Open.
- `self.hit`: Full damage. Nothing between him and it.

## c9 — Arnie `[c9]`
> He unwraps one hand and nods at you. "That's the whole job. Read what they're about to do, then do something about it. And the more you practise a move, the better you get at it. Eventually you'll be able to do much more with it too."

## c10 — Arnie `[c10]`
> "First three sessions are on me. After that it's fifteen quid, and the rent on this place isn't cheap."

## c11 — Archie `[c11]`
> He pulls his jacket back on, checking his phone. "Told you. I've got your pearls to shift. I'll text you." He's through the shutter before you can thank him.

---

## On complete `[gym.on_complete]`
Not shown as card text, but the player receives a queued phone message:
- Contact `archie`, kind `archie_sells_pearls`: "Pearls are sorted. Come by when you're free." `[on_complete[1].text]`
- Then: sets flag `gymUnlocked`, switches to phone screen.

---

## Related: gym Spar lines (post-tutorial, `data/combat_rounds.json` → `spar.lines`)
Not part of the tutorial sequence, but same gym voice; included for consistency when rewriting.

- `intro`: Flip Reverse. The arch rattles when a train goes over. Mats down, gloves on. Arnie's house rules apply.
- `houseRules`: Arnie's house rules: Rewind is free and there's no limit. When it's over, the gym rewinds you to the start: no bruises, nothing spent.
- `endRewind`: The gym winds you back to the morning. Not a bruise on you, kit all present. The XP stays.
- `noTime`: No time blocks left today.
- `locked`: The gym isn't open to you yet.
- `cantPay`: Not enough for the session fee.
- Partner names (`spar.partners[].name`): Gym newcomer (Easy), Regular (Even), Old hand (Hard).
