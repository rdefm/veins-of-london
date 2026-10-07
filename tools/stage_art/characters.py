"""Character configs for the character kit (char_kit.py).

Colours are lit tones; each style builds its own shadow ramp under them. Keys:
  build        height / width (1.0 = Archie), stoop (px the head drops; rounds the shoulders)
  skin, eyes   mid-tone colours
  hair         kind curly | short | thinning, colour, lock (a curl over the forehead)
  facial_hair  kind beard | stubble | moustache | None, colour
  brows        colour (defaults to darkened hair)
  glasses      frame colour or None
  outfit       top {kind jacket | jumper | waistcoat, colour, cuffs}, under {kind tee | shirt,
               colour}, trousers, shoes, soles
  expression   smile | neutral (what the "closed" mouth frame shows)
  lines        age lines on the forehead
  props        held-prop groups whose arm frames the rig gets: wrap, phone, bag, vial
"""

# Archie_reference.png: warm smile, dark-brown loose curls with a lock over the
# forehead, full short beard joined to the moustache, olive overshirt with
# rolled cuffs over a stone tee, black slim jeans, white trainers.
ARCHIE = dict(
    id="archie",
    build=dict(height=1.0, width=1.0, stoop=0),
    skin="#dca47e",
    eyes="#2b170d",
    hair=dict(kind="curly", colour="#4f311c", lock=True),
    facial_hair=dict(kind="beard", colour="#47301f"),
    brows="#24140c",
    glasses=None,
    outfit=dict(
        top=dict(kind="jacket", colour="#4b5535", cuffs=True),
        under=dict(kind="tee", colour="#ddd8cf"),
        trousers="#2c2d36",
        shoes="#f2efe8",
        soles="#c4beb4",
    ),
    expression="smile",
    lines=False,
    props=["wrap", "phone", "bag", "vial"],
)

# James_reference.png: older, wild thinning grey hair, glasses, navy waistcoat
# over a pale blue shirt, grey trousers, brown shoes. Kit demo only for now.
JAMES = dict(
    id="james",
    build=dict(height=0.96, width=1.05, stoop=1),
    skin="#e2b79c",
    eyes="#2a2a33",
    hair=dict(kind="thinning", colour="#dad8d4", lock=False),
    facial_hair=None,
    brows="#9a958e",
    glasses="#3a3a44",
    outfit=dict(
        top=dict(kind="waistcoat", colour="#34446a", cuffs=False),
        under=dict(kind="shirt", colour="#c3d6ea"),
        trousers="#686b75",
        shoes="#7a5237",
        soles="#46301f",
    ),
    expression="neutral",
    lines=True,
    props=[],
)

CHARACTERS = {"archie": ARCHIE, "james": JAMES}
