# James meeting — proposal 2

Rewrite of `data/events/james_meeting.json` against `writing-guide.md`, borrowing from `james-meeting-proposal.md` (ledger tell, gloves, "Less pressure at the edge. Again"). 24 cards (was 23).

1. **Hook + focus.** Opens on Archie with no pearls since Whitechapel, checking the street: a concrete need, not a lore intro. Money stays on screen: pearls "at cost", £120 a pearl vs "my calc on the floor", a ledger of losses. Last card points at the next payday (the right buyer), which hands off to `archie_craft_chat`.
2. **Brevity.** Cut the walk-in description of the workbench and Archie's "Yeah, alright". Instruction is one card of dialogue plus one craft card.
3. **Humour beside danger.** Two anchors: "I'm the only craftsman you know" and the Critias put-down/Poundland musing, both next to stakes (Archie's errand, wasted calc). Small deadpan: "Ring me if he's horrible." The one permitted James profanity is kept, attached to the cost of calc.
4. **People, not plot devices.**
   - *Archie:* tell = checking the street; care = sets this up, then lets you choose ("Your call"), asks whether the seller is dangerous; want = pearls at cost; canon trait = rubs his eyes and stays by the shutter in a room of calc (symptom only, the allergy was explained in `intro`); exit = gone before James can reply.
   - *James:* tell = the ledger; care = says nothing about failed spheres, pays you in pearls, gives you a kit and calls it spare; want = his order filled; canon hint = the jar reacts to you, something in his expression shifts, then he sends Archie away, keeps you back, and puts that same jar in front of you. Never explained.
   - *You:* stay for a concrete reason (the knife, rent), not because crafting was offered. James only names the task once Archie has gone.
5. **Handoff.** Label matches `buyer.json` ("Tomorrow… behind the Costcutter. Midday"), was "Two days later". Archie's pending text called James "the best craftsman I know", so the line is set up. Archie leaving for Stratford explains why the next event opens with his text.

```json
{
  "id": "james_meeting",
  "cards": [
    { "type": "narration", "label": "Midday — Bermondsey", "speaker": null, "text": "The storage unit behind the Costcutter. Archie is already there, which has never happened before. He used his last pearl in Whitechapel, and since then he checks the street every time a car slows." },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"James makes pearls. I need pearls. Next time someone gets a knife out, I'd like more than a carrier bag to wave at them. So be polite, touch nothing, and let me do the talking.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "The shutter rattles up. James is in his sixties: glasses with one bent arm, a cardigan with a pencil in the pocket. He looks at Archie, then at you, like a parcel left on the wrong doorstep." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"You're early. That's new. Come in. Touch nothing.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "Shelves of jars run to the ceiling, each labelled in biro. It smells of copper and bleach. Archie stays by the shutter and rubs his eyes." },
    { "type": "narration", "label": null, "speaker": null, "text": "You pass a jar marked TIME. The calc inside shifts. It moves to the side of the glass nearest your hand, as if it noticed you." },
    { "type": "narration", "label": null, "speaker": null, "text": "You glance up. James is watching you. His expression doesn't change, exactly. But something in it does." },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"James is the best craftsman I know. That pearl in Whitechapel was one of his.\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"I'm the only craftsman you know. There's a difference.\" He turns to Archie. \"Forty units of life calc, collected from Stratford within the hour. Do it and your next batch of pearls is at cost.\"" },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"Who's the seller? Anyone I need to worry about?\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Nobody who's ever shortchanged me. The address will be on your phone by the time you reach the station.\" He doesn't look at you. \"I need your friend's assistance with something in the meantime.\"" },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "He looks at you, not James. \"Your call. Stay here, or come to Stratford and carry a bag.\"" },
    { "type": "speaker", "label": null, "speaker": "You", "text": "You think about the pearl that stopped the knife, and about rent. \"I'll stay.\"" },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"Lovely. Ring me if he's more horrible than usual.\" He's gone before James can answer." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "He takes down the jar marked TIME and sets it on the bench. \"My assistant is indisposed and I have an order for time pearls. You'll do.\" A pause. \"That wasn't a compliment. Gloves.\"" },
    { "type": "speaker", "label": null, "speaker": "You", "text": "\"I've never made one.\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Evidently. So I'll explain it once. A pearl that seals is worth a hundred and twenty pounds to someone frightened. A pearl that doesn't is my calc on the floor. Do try not to fuck it up.\"" },
    { "type": "craft", "label": "Crafting: Time Pearl", "speaker": null, "text": "A measure of time calc, a glass sphere, steady pressure from both palms. Get it right and the sphere seals itself around the calc. Get it wrong and the calc clouds and drains away. The calc does the work. You're the hands." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "Your first sphere clouds over. James logs the loss and measures out another. \"Plato wrote about orichalchum in the Critias. Second only to gold, in Atlantis.\" He glances at you. \"You have no idea what the Critias is, do you.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "It isn't really a question. You don't answer it." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Two and a half thousand years ago, people knew exactly what this was worth. Today Archie is collecting it outside a Poundland in Stratford. Make of that what you will about humanity.\" He nods at the sphere. \"Less pressure at the edge. Again.\"" },
    { "type": "resolution", "label": "Two hours later", "speaker": null, "text": "Some spheres seal. More don't. James logs every failure and says nothing about any of them. At the end he puts two good pearls on your side of the bench, and a battered crafting kit on top." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Consider the kit and two pearls payment. When practicing and you may yet be able to make a more than a living out of this.\"" },
    { "type": "resolution", "label": null, "speaker": null, "text": "The shutter comes down behind you. Two pearls in your pocket: one for the next knife, one for the right buyer. Archie will know the buyer." }
  ],
  "on_complete": [
    { "op": "add_item", "item": "timePearl", "qty": 2 },
    { "op": "set_flag", "flag": "metJames", "value": true },
    { "op": "set_flag", "flag": "craftingUnlocked", "value": true },
    { "op": "add", "path": "contacts.james.unlocked", "value": true },
    { "op": "relation", "contact": "james", "value": 10 },
    { "op": "set_stage", "value": "archie_craft_chat" },
    { "op": "queue_pending_message", "contact": "archie", "kind": "archie_craft_chat", "text": "Oi — how'd it go with James? Come find me." },
    { "op": "add", "path": "world.archieChatUnlockDay", "value": 1 },
    { "op": "set_screen", "screen": "phone" }
  ]
}
```

`id`, `on_complete` and the `craft` card type unchanged; event has no images. Only label change of note: "Two days later — Bermondsey" → "Midday — Bermondsey" (matches `buyer.json`). `data/events/james_meeting.json` untouched.

## Open points for review

- **Physics vs life calc.** Kept "physics calc, forty units" per `docs/REFERENCE.md` §patch list. Proposal 1 switched to life, citing your edit; if that's intended, REFERENCE.md needs updating too. (Proposal 1 also spelled it "orichalcum"; canon is "orichalchum".)
- **£120.** Taken from `CONSUMABLE_PRICES.timePearl` (still "needs balance sign-off"). Could go vague ("a lot of money to someone frightened") if the price may move.
- **Archie by the shutter.** Reads raw calc as irritating his allergy at range. Intro only showed it on use. Cut the eye-rub if that's a stretch.
- **"Nobody who's ever stabbed me."** Could read as a third joke. Alternative: "Nobody you need to worry about."
- **Simile.** "like a parcel left on the wrong doorstep" is the scene's one simile ("as if it noticed you" is borderline a second). Cut the parcel to "He looks at Archie, then at you." if it feels ornate.
- **"Second only to gold."** Plato's Critias ranks orichalcum below gold only. Swap to the old "second most precious metal" phrasing if preferred.
- **Final card.** "One for the right buyer" pre-empts Archie's resale pitch in `archie_craft_chat`. It works as a setup, or end on "Two pearls in your pocket, and a kit you're not to bring back."
