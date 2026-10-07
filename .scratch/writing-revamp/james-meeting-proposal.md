# James meeting — proposed rewrite

The calc responds to the player, and James notices without discussing it. He uses the pearl order to see whether the player improves with instruction. His impatience stays visible even as he gives them another try. The two finished pearls and all completion effects stay as written.

Proposed continuity change: the Stratford pickup uses **forty units of life orichalcum**, per your edit. The current game event and `docs/REFERENCE.md` use physics calc.

```json
{
  "id": "james_meeting",
  "cards": [
    { "type": "narration", "label": "Midday — Bermondsey", "speaker": null, "text": "Behind the Costcutter, Archie waits beside a storage-unit shutter. He checks his phone, then the street. You have never seen him early for anything." },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"James knows I'm bringing you. Let me do the talking.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "The shutter rises. James is in his sixties, with a bent arm on his glasses and a pencil tucked into his cardigan pocket. He looks at Archie, then at you." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"You're blocking the entrance. Come in.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "Jars line the walls, each labelled by hand. As you pass one, the calc inside pushes against the glass nearest your hand. You step back; it settles." },
    { "type": "speaker", "label": null, "speaker": "You", "text": "\"That one moved.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "James's eyes move from the jar to your hand. He sets the jar farther back on the shelf and turns to Archie." },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"James is the best craftsman I know. Made the pearl that got us out of Whitechapel.\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"I'm the only craftsman you know. A poor basis for comparison. Archie, I need a collection made in Stratford. I'll sell you the next batch of pearls at cost if you go now.\"" },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"What am I collecting?\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Forty units of life orichalcum. The address will be on your phone before you reach the station. You have forty-five minutes.\" He pulls two pairs of gloves from a drawer. \"Your associate stays.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "James gives you one pair. Archie waits until you take it." },
    { "type": "speaker", "label": null, "speaker": "You", "text": "\"I'll stay. I want to know how to make the thing that stopped that knife.\"" },
    { "type": "speaker", "label": null, "speaker": "Archie", "text": "\"Fair. Ring me if you need me.\" He waits for your nod, then goes." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"My assistant is absent. I have an order for time pearls. If you can follow an instruction, you can be useful.\"" },
    { "type": "speaker", "label": null, "speaker": "You", "text": "\"I've never made one.\"" },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Plainly. Gloves on. Touch only what I hand you.\"" },
    { "type": "craft", "label": "Crafting: Time Pearl", "speaker": null, "text": "James shows you how to compress time calc into a glass sphere. It seals itself if the pressure is right. Then he measures out the same amount and puts it in front of you." },
    { "type": "narration", "label": null, "speaker": null, "text": "Your first sphere clouds over and empties. James records the loss in his ledger. He puts out another measure." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"Plato wrote about this in the Critias. He didn't say who paid for the failed batches. Less pressure at the edge. Again.\"" },
    { "type": "narration", "label": null, "speaker": null, "text": "The second sphere seals around a pale thread of calc. James checks it, leaves it on your side of the bench, and puts out a third measure." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"That one will hold. Don't look pleased yet. Make the next without me talking you through it.\"" },
    { "type": "resolution", "label": "Two hours later", "speaker": null, "text": "You seal another pearl without his help. James checks it twice, then packs both pearls with an old crafting kit. He closes his ledger before you can see the total." },
    { "type": "speaker", "label": null, "speaker": "James", "text": "\"The kit's spare. Don't bring it back. Keep practicing.\"" },
    { "type": "resolution", "label": null, "speaker": null, "text": "Outside, you put the box deep in your coat pocket. James has already pulled the shutter down. You text Archie that you're done." }
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

Proposal only; `data/events/james_meeting.json` is unchanged.
