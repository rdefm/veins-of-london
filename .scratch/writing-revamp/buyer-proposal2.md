# buyer — imported from data/events/buyer.json

```json
{
  "id": "buyer",
  "on_complete": [
    {
      "op": "add",
      "path": "player.cash",
      "value": 40
    },
    {
      "op": "set_flag",
      "flag": "buyerEventSeen",
      "value": true
    },
    {
      "op": "set_stage",
      "value": "sms_archie"
    },
    {
      "op": "push_message",
      "contact": "archie",
      "from": "player",
      "text": "You mentioned a bloke called James. When can we sort that?"
    },
    {
      "op": "push_message",
      "contact": "archie",
      "text": "Already arranged. Tomorrow — SE1 4YA, storage unit behind the Costcutter. Midday."
    },
    {
      "op": "queue_pending_message",
      "contact": "archie",
      "kind": "james_meeting",
      "text": "Fair warning: James is the best craftsman I know and also the worst person I know. Don't take it personally. He's like that with everyone."
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "The next morning",
          "speaker": null,
          "text": "Archie texts an address in Shoreditch and the word \"tonight\". You arrive to find him outside a craft beer bar, looking mildly disgusted by its existence.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Right. Same calc as the other night — I kept hold of the bag. Buyer's inside. Name's Marcus, finance, collects emotion-type for what he calls 'recreational use'. Don't ask. Just be normal. Or close to it.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"This is the same stuff. From when they tried to rob us.\"",
          "key": "c3"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Correct. Which is why having two of us is better than one. You're essentially a deterrent. Like a scarecrow. No offence.\"",
          "key": "c4"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Some offence.\"",
          "key": "c5"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Noted.\"",
          "key": "c6"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Marcus is exactly what you expected: fleece, Patagonia, very clean trainers. He examines the calc with the careful enthusiasm of someone who has recently read about it online. He pays promptly, which is nice.",
          "key": "c7"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"See? Smooth as you like. Most of them are like Marcus. Professional, prompt, no Stanley knife. That's the market we're targeting.\"",
          "key": "c8"
        },
        {
          "type": "resolution",
          "label": "Walking back — Shoreditch High Street",
          "speaker": null,
          "text": "Archie splits the cash on the pavement outside a Pret. The city moves around you, completely indifferent to any of this. Your share is in the bank before you reach the corner. You open the app and look at the rent line. It's moved. Not far enough.",
          "key": "c9"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So. I've got a contact who knows a lot more about this than I do. Bloke called James — craftsman, Bermondsey. Takes raw calc and makes things out of it. Your hourglass, for one. I've been meaning to introduce you.\"",
          "key": "c10"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"Sure.\"",
          "key": "c11"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"I'll set it up. Give me a bell tomorrow.\"",
          "key": "c12"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete"
    ],
    "cards": {
      "c1": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c10": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c11": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "buyer.json",
  "_liveHash": "00c90d01"
}
```
