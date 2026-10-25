# biz_a1_proposition — imported from data/events/biz_a1_proposition.json

```json
{
  "id": "biz_a1_proposition",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "bizA1PropositionSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "bizArchieSalesRole",
      "value": true
    },
    {
      "op": "set_contact_role",
      "contact": "archie",
      "role": "sales"
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
          "key": "c1",
          "type": "narration",
          "label": "Bermondsey — James's unit",
          "speaker": null,
          "text": "James answers the door and shows you inside. Archie is already there, standing well back from the shelves, the way he always does - partly the allergy, partly James.",
          "image": "res://assets/events/biz_a1_proposition/biz_a1_proposition_main_1.png"
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Right. Before James starts: you've got two veins going. Two's not a hobby. Two's a supply.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"So here's the pitch. I sell. James makes. You grow it. Everyone does one job properly instead of three badly, and we split what comes in.\""
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "James has a small brass hourglass on the workbench. He turns it over while Archie talks, and again when Archie stops. It is an ordinary hourglass you've seen him use to time glue."
        },
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You are proposing that I go into business with a man who cannot stand within two metres of his own product, and someone I taught to make a pearl.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"When you say it like that it sounds bad.\""
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I said it accurately.\""
        },
        {
          "key": "c13",
          "type": "narration",
          "text": "James stares at the floor a few moments before looking at Archie, who is rubbing his now-red eyes. James then looks at you.",
          "image": "res://assets/events/biz_a1_proposition/biz_a1_proposition_main_8.png"
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I have my own business. It carries on whatever I decide here. If I put my name to a second business, I want two things first.\""
        },
        {
          "key": "c9",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"One: a proven market that pays reliably. Three orders delivered in full. Not most of an order - in full. Whatever you have already delivered counts. I have no wish to watch you repeat yourself.\""
        },
        {
          "key": "c10",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Two: a serious investment. Anyone can sell a few jars. I want to see you put money into this that you would miss.\""
        },
        {
          "key": "c11",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Market and money. Done.\" He's already on his phone, then says to you, \"I'll send you proper orders - buyers I know pay. They'll come through on BizBrief.\""
        },
        {
          "key": "c12",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "James turns the hourglass once more and goes back to his table. He has not said yes. He has not said no, either, and Archie is treating that as a signature."
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
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c8": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c10": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c11": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "biz_a1_proposition.json",
  "_liveHash": "72230874"
}
```
