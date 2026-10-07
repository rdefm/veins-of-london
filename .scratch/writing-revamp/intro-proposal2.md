# Intro event — proposal 2

Revision of `intro-proposal.md`. 17 cards (was 18), shorter per card. Goals:

1. **Hook + focus.** Opens on money, not magic: rent, £40, a sale. Magic arrives as a thing that happens, then gets explained as *stock* ("Someone finds it... people like us stand in the middle"). That sentence is the game's pitch; the closing line points at the calc in the bag as the next payday.
2. **Brevity.** Pre-deal setup is four short cards. Pub Q&A cut to one question about what calc is, one about the job. "You slowed time?" / "magic has expenses?" exchange dropped.
3. **Humour beside danger.** Two anchor jokes plus Archie's salesman deadpan
   - Cockney comes from word choice and rhythm ("lads", "leg it", "innit", "ain't I", "lovely"), never phonetic spelling.
4. **Archie as a person.** Whistling; salesman patter before the deal; tells you to run without him; **steps between you and the knife** without comment; pays for chips and frames it as business ("You're no use to me keeling over"); gives you honest odds; leaves before you can thank him. Generous in deed, not word, per CHARACTER-VOICE-GUIDE.
5. **Tone bible / handoff.** No exclamation marks in narration, one simile (the canon "buffering"). Calc stays "the calc from tonight" so `buyer.json`'s "Same calc from the other night" still lands; "I'll text you" matches its opening text.

```json
{
  "id": "intro",
  "cards": [
    {
      "type": "narration",
      "label": "Earlier tonight — Whitechapel",
      "speaker": null,
      "text": "Rent is due Friday. You have £40, and this morning's interviewer has promised to keep your details on file. Archie, an old mate, said he might have work. So: half ten on a Tuesday, behind a chicken shop on Mile End Road."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "He's whistling, a Tesco bag hooked on one finger. \"Two blokes, cash, in and out before the chicken shop shuts. You just stand there looking like you'd be a pain to fight. If I say leg it, you leg it. Don't wait for me.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"I don't look like I'd be a pain to fight.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Pretend then. Imagine you're Vinnie Jones in his prime.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "He looks you up and down. \"You've got a bit more of a Mr Bean vibe, but you make do with what you've got, innit?\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "The buyers arrive in a grey Vauxhall. Three of them. That's one more than Archie mentioned. He stops whistling.",
      "image": "res://assets/events/intro/1.jpg"
    },
    {
      "type": "tension",
      "label": "It goes wrong",
      "speaker": null,
      "text": "The nearest one opens a Stanley knife and comes at you, not Archie. Archie shifts his weight, and is suddenly standing in the gap between you. The third man stays at the mouth of the alley, which is somehow worse.",
      "image": "res://assets/events/intro/2.jpg"
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Alright, lads. No need for all that.\" He lifts the bag high, and every eye follows it. \"It's all here. Have a look.\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "His other hand flicks out of his back pocket. Something small hits the tarmac between the men and breaks. They slow. Not stopped — slow, like a video buffering. The knife is still coming. It will take a while."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Coming, or what?\""
    },
    {
      "type": "resolution",
      "label": "Fifteen minutes later — a Wetherspoons",
      "speaker": null,
      "text": "Archie buys two pints and chips, puts the chips on your side of the table, and sits facing the door. His eyes are streaming.",
      "image": "res://assets/events/intro/3.png"
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"What was that?\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Calc. Orichalchum, if you're being posh about it. That one was time-type. Slows everything round it for a few seconds.\" He dabs his eyes with a napkin. \"Last one I had, and all. Allergic to the stuff, before you ask. Don't.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"It's stock, innit. Someone finds it, someone makes it useful, someone pays through the nose for it. People like us stand in the middle and take a cut. Normally nobody gets a knife out.\" He nods at the chips. \"Eat. You're no use to me keeling over.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Still got tonight's calc, ain't I. I'll find a proper buyer. Somewhere with lights. And witnesses. You come along, you get a cut. You've seen how it goes wrong, so no hard feelings if it's a no.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "You look at the door, at the chips, then think about your bank balance. \"I'll come.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Lovely. I'll text you.\" He's out the door before you can thank him, for the chips or the knife."
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "Rent is still due Friday. But somewhere on Mile End Road, in a Tesco bag, is the calc that might pay it.",
      "image": "res://assets/events/intro/4.png"
    }
  ],
  "on_complete": [
    { "op": "set_flag", "flag": "metArchie", "value": true },
    { "op": "set_stage", "value": "buyer_event" },
    { "op": "set_screen", "screen": "phone" }
  ]
}
```

`id`, `on_complete`, and the four image placements unchanged. `data/events/intro.json` untouched.

## Open points for review

- **"It will take a while."** Dry beat on the knife; could read as a third joke. Cut if so.
- **Allergy on contact.** VISION.md defines allergy as "can't consume; direct effects hurt". Streaming eyes from handling one is a light reading of that. Keep, or swap for a sneeze?
- **Final card.** "somewhere on Mile End Road" assumes Archie lives/stays nearby. Alternative: "...in Archie's Tesco bag, is the calc that might pay it."
