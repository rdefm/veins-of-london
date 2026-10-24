# wren_introduction — imported from data/events/wren_introduction.json

```json
{
  "id": "wren_introduction",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "wrenIntroductionSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "wrenRecipesUnlocked",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "assayCommissionsUnlocked",
      "value": true
    },
    {
      "op": "set_screen",
      "screen": "contacts"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "The City — the Guild registry",
          "speaker": null,
          "text": "The door on the third floor does say STATIONERY. Behind it: a counter, a brass bell, a coat stand with no coats, and a woman writing in a ledger with a fountain pen.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "She finishes the line before she looks up. \"You'll be James's letter. He used the word 'adequate'. From James, that's practically a reference.\"",
          "key": "c2"
        }
      ],
      "then": [
        {
          "if": {
            "flag": "wrenMetBeforeIntro"
          },
          "branch": "b3"
        },
        {
          "branch": "b4"
        }
      ]
    },
    "b3": {
      "title": "From card 3",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "\"We've already exchanged messages, of course. It's nice to put a face to the file.\"",
          "key": "c3"
        }
      ],
      "then": {
        "branch": "b4"
      }
    },
    "b4": {
      "title": "From card 4",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "She turns the ledger round to face you. \"I'm registering you as an associate, not a member. Members need a sponsor, a vote and a dinner nobody enjoys. Associates need a signature.\"",
          "key": "c4"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"What does an associate get?\"",
          "key": "c5"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "\"Recipes. James said he's helping you with Time and Life. Everything else can be supplied by the Guild, and I keep the catalogue. The basic procedures are for sale to any associate; more advanced recipes depend on your standing.\"",
          "key": "c6"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Ingram",
          "text": "A door opens behind the counter. A tall man in a grey suit reads the ledger upside down without slowing. He gives you a quick glance \"Associate. Hm. Perhaps best to write their name in pencil, Registrar.\"",
          "key": "c7"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Wren waits for the door to close. Then she uncaps the pen again and writes your name in ink.",
          "key": "c8"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "\"Dr Ingram runs the Assay department. The Guild trusts what it has tested, so you'll need to work hard to become more than an Associate. I'll send you commissions for items. Deliver well and we may consider selling more advanced recipes to you.\"",
          "key": "c9"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Wren",
          "text": "She blots the page. \"I've spent eleven years getting an associate register past the Court. You're the fourth name in it. Please don't be the reason it closes.\"",
          "key": "c10"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "She files the page under A, behind three others. You head out, wondering when your first commission will arrive. On your way out you pass a door marked ASSAY. It's shut, and the light is on.",
          "key": "c11"
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
        "text",
        "goto"
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
      ]
    }
  },
  "_liveSource": "wren_introduction.json",
  "_liveHash": "81077dff"
}
```
