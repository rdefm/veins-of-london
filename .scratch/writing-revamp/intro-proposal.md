# Intro event — proposed rewrite

The scene keeps the failed deal, Archie's last Time Pearl, the escape, and the next-day buyer setup. The player now knows why Archie brought them; Archie's warning and small acts of care make their friendship visible. The humour comes from his treating a dangerous job like ordinary work.

```json
{
  "id": "intro",
  "cards": [
    {
      "type": "narration",
      "label": "Earlier tonight — Whitechapel",
      "speaker": null,
      "text": "Rent is due Friday. You have £40 left, and this morning's interviewer promised to keep your details on file. Archie, an old friend, said he might have work. Now you are behind a chicken shop on Mile End Road at half ten on a Tuesday, watching him hold a Tesco bag around an opened cardboard box."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Just stand with me. It's a sale. You don't have to say anything. If I tell you to leave, you leave.\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "The buyers arrive in a grey Vauxhall. Three of them. That's one more than Archie mentioned. He notices too - you can tell by the way he stops whistling.",
      "image": "res://assets/events/intro/1.jpg"
    },
    {
      "type": "tension",
      "label": "It goes wrong",
      "speaker": null,
      "text": "The nearest man opens a Stanley knife. Another reaches for the bag. The third stays by the mouth of the alley. Nobody has said a word.",
      "image": "res://assets/events/intro/2.jpg"
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Yeah, ok.\" Archie saiys quietly. He raises the bag where they can all see it. \"Alright. Easy.\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "His other hand slips into his pocket, then flicks out. Something small strikes the ground between the men and breaks. They stop, looking like mannequins. Even the knife stays where it is, halfway to you. Archie is already moving."
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Coming, or what?\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "You follow him onto Mile End Road. Behind you, someone shouts. Archie still has the bag. There are people on the pavement now; the three men stay in the alley."
    },
    {
      "type": "resolution",
      "label": "Fifteen minutes later — a Wetherspoons",
      "speaker": null,
      "text": "Archie orders two pints and chips. He checks the door once before sitting down. Neither of you speaks until the food arrives.",
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
      "text": "\"Orichalchum. Calc, usually. That was time-type, made to slow things down. Or slow people down. Bought us a few seconds.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"You... slowed time? And you knew you'd have to do that for this deal?\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"I didn't know I'd need it, but you never do. That's why I carried it. Last one, too. I'll put it under expenses.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "\"You're telling me magic has expenses?\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"It's just like any product-  some people source it, some people turn it into something useful, some people use it. In between all that, people like us can make a quid or two connecting them. Usually nobody needs a knife.\" He pushes the chips towards you. \"Eat.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"The calc in the bag's still mine. I'll line up another buyer tomorrow, somewhere public. You need the rent; I need someone with me. You'll get a cut. You've seen what can go wrong, so you can say no.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "You",
      "text": "You look at the door, then at the chips, then think of your bank balance. \"I'll come.\""
    },
    {
      "type": "speaker",
      "label": null,
      "speaker": "Archie",
      "text": "\"Good. I'll text you in the morning. Finish those; I paid for them.\""
    },
    {
      "type": "narration",
      "label": null,
      "speaker": null,
      "text": "He leaves without waiting to be thanked. Your rent is still due Friday. For now, there is a plate of chips, a promise of a cut, and the memory of a knife that stopped four inches from your coat.",
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

The `on_complete` effects and four image placements are unchanged. This is a writing proposal; `data/events/intro.json` remains untouched.
