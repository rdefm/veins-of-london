# prologue_pub — imported from data/events/prologue_pub.json

```json
{
  "id": "prologue_pub",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "metArchie",
      "value": true
    },
    {
      "op": "set_stage",
      "value": "buyer_event"
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
          "type": "choice",
          "label": "Fifteen minutes later — a Wetherspoons",
          "speaker": null,
          "text": "Archie buys two pints and chips, puts the chips on your side of the table, and sits facing the door. His eyes are streaming. You have so many questions you aren't sure where to start.",
          "image": "res://assets/events/intro/intro_main_11.png",
          "advance": "anytime",
          "choices": [
            {
              "id": "whatIsIt",
              "label": "\"What was that stuff?\"",
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b2"
              }
            },
            {
              "id": "howMuch",
              "label": "\"How much is it worth?\"",
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b3"
              }
            },
            {
              "id": "whereFrom",
              "label": "\"Where does it come from?\"",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "introAskedSource",
                  "value": true
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b4"
              }
            },
            {
              "id": "eatChips",
              "label": "Eat a chip",
              "exit": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b5"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b2"
      }
    },
    "b2": {
      "title": "From card 2",
      "cards": [
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Calc. Orichalchum, if you're being posh about it. That one was time-type. Slows everything round it for a few seconds. Last one I had, and all.\" He dabs his eyes with a napkin. \"I'm allergic to the time type, before you ask. Don't.\"",
          "goto": {
            "branch": "main"
          }
        }
      ],
      "then": {
        "branch": "b3"
      }
    },
    "b3": {
      "title": "From card 3",
      "cards": [
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"The calc? Depends who's buying. Bit of time-type like that, seventy-odd quid a chip.\" He dabs his eyes with a napkin. \"Ten chips, you're looking at seven hundred and fifty. Which is why that lot wanted to fight for it.\"",
          "goto": {
            "branch": "main"
          }
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
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Calc grows. Don't laugh.\" He dabs his eyes with a napkin. \"Things called 'veins' grow the stuff, if you know how to take care of them and are patient. Most of them, someone's already sitting on.\"",
          "goto": {
            "branch": "main"
          }
        }
      ],
      "then": {
        "branch": "b5"
      }
    },
    "b5": {
      "title": "From card 5",
      "cards": [
        {
          "key": "c5",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"It's stock, innit. Someone finds it, someone makes it useful, someone pays through the nose for it. People like us stand in the middle and take a cut.\" He nods at the chips. \"Eat. You're no use to me keeling over.\""
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Normally nobody gets a knife out. Still got tonight's calc, ain't I. I'll find a proper buyer. Somewhere with lights. And witnesses. You come along, you get a cut. You've seen how it goes wrong, so no hard feelings if it's a no.\"",
          "image": "res://assets/events/intro/intro_main_13.png"
        },
        {
          "key": "c7",
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "You look at the door, at the chips, then think about your bank balance. \"I'll come.\""
        },
        {
          "key": "c8",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Lovely. I'll text you.\" He's out the door before you can thank him, for the chips or the hourglass."
        },
        {
          "key": "c9",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Rent's still due Monday. But somewhere on Mile End Road, in a Tesco bag, is the calc that might pay it.",
          "image": "res://assets/events/intro/intro_main_16.png"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "on_complete",
      "cards"
    ],
    "cards": {
      "c1": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "image",
        "advance",
        "choices"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
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
        "text",
        "image"
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
        "text",
        "image"
      ]
    }
  },
  "_liveSource": "prologue_pub.json",
  "_liveHash": "5f308d07"
}
```
