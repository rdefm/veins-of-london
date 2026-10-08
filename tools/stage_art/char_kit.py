"""Character kit: people in three pixel-art styles, driven by a config.

A style fixes rendering, proportions and face stamps; a character config
(characters.py) fixes build, hair, facial hair, glasses, outfit colours and
held props. build(style, char) returns the rig's part PNGs, manifest() its rig
manifest. Canvas 96x168 and origin (48,159) match rig_archie.py, so any output
drops into the engine as a rig. Styles:

  chibi      SNES/Stardew-style RPG: ~2.5 heads tall, big eyes, flat 3-tone
             cel shading, uniform dark outline.
  adventure  Point-and-click adventure (LucasArts/Wadjet Eye): lanky, small
             head, hue-shifted 4-tone ramps, coloured sel-out outline, no dither.
  retro      NES/PICO-8-style: drawn at half resolution then doubled, 2 tones
             per material, hard black outline.
  minimal    Tiny "pixel people": drawn at third resolution, ~4.5 heads tall,
             flat 2-tone colour, no outline, dot eyes.
  minimal_plus  Between minimal and retro: minimal's slim build drawn at half
             resolution, 3-tone ramps, soft sel-out outline, 1x2 eyes, nose.

Everyone stands in a three-quarter view turned toward viewer-right (TURN):
face features and the clothes' front line sit right of centre, the far
(viewer-right) shoulder tucks in, both feet point right, the near leg in front.

Arms are posed by 2-bone IK from a shared pose table scaled to each style's
arm length, so the same rig actions work for every style and character.
"""
import colorsys
import math

from PIL import Image

from raster import Canvas, Material, darken, hexc

W, H = 96, 168
ORIGIN = (48, 159)
TURN = 0.35

# Hand targets relative to the shoulder, in units of rig_archie's arm (length 38),
# an elbow hint (which side the elbow bends to) and the held prop. Viewer-left
# arm (arm_l); arm_r entries are written for the viewer-right arm directly.
POSE_L = {
    "rest": ((2, 37), (-4, 18), None),
    "hold": ((6, 24), (-5, 18), "wrap"),
    "eat": (None, (-4, 18), "wrap"),
    "wave_a": ((-13, -12), (-12, 6), "wrap"),
    "wave_b": ((-18, -10), (-12, 6), "wrap"),
    "crumple": ((6, 22), (-5, 18), "ball"),
    "throw_back": ((-5, -14), (-12, 2), "ball"),
    "throw_release": ((-24, -6), (-12, 6), None),
    "bag": ((-2, 36), (-6, 18), "bag"),
    "bag_wave_a": ((-13, -12), (-12, 6), "bag"),
    "bag_wave_b": ((-18, -10), (-12, 6), "bag"),
}
WRAP_ANGLE = {"hold": -60, "eat": -55, "wave_a": -95, "wave_b": -120}
BAG_SWING = {"bag": 0, "bag_wave_a": 8, "bag_wave_b": -22}
POSE_R = {
    "rest": ((-2, 37), (4, 18), None),
    "phone_up": ((-8, 10), (4, 18), "phone_up"),
    "phone_low": ((2, 33), (5, 18), "phone_low"),
    "pocket": ((-3, 31), (9, 16), "behind"),
    "vial": ((1, 33), (5, 18), "vial"),
    "flick_back": ((-1, 31), (5, 18), "vial_back"),
    "flick": ((5, 32), (5, 18), None),
    "knife_low": ((3, 33), (5, 18), "knife"),
    "knife": ((14, 20), (4, 22), "knife"),
}
VIAL_ANGLE = {"vial": -90, "vial_back": -150}
KNIFE_ANGLE = {"knife_low": -20, "knife": -35}
# Far-arm frames whose sleeve passes behind the torso in the three-quarter view.
FAR_TUCKED = {"rest", "pocket", "vial", "flick_back", "flick"}
# Held-prop tag -> the config prop group that unlocks frames using it.
PROP_GROUP = {"wrap": "wrap", "ball": "wrap", "phone_up": "phone", "phone_low": "phone",
              "bag": "bag", "vial": "vial", "vial_back": "vial", "behind": "vial", "knife": "knife"}
EYE_FRAMES = ["open", "down", "closed", "wide"]
BROW_FRAMES = ["normal", "up", "knit", "quirk"]
MOUTH_FRAMES = ["closed", "chew_a", "chew_b", "talk_a", "talk_b", "agape", "smirk", "whistle"]
# Walk cycle (moving right): per leg (stride dx in units of the stride, lift in units of the lift).
WALK = [((-1, 0.4), (1, 0)), ((0, 1), (0, 0)), ((1, 0), (-1, 0.4)), ((0, 0), (0, 1))]
ACTIONS = {
    "bag_wave": [
        {"t": 0.0, "set": {"arm_l": "bag_wave_a"}}, {"t": 0.2, "set": {"arm_l": "bag_wave_b"}},
        {"t": 0.4, "set": {"arm_l": "bag_wave_a"}}, {"t": 0.6, "set": {"arm_l": "bag_wave_b"}},
        {"t": 0.8, "set": {"arm_l": "bag_wave_a"}}, {"t": 1.05, "set": {"arm_l": "bag"}},
    ],
    "pocket_draw": [{"t": 0.0, "set": {"arm_r": "pocket"}}, {"t": 0.55, "set": {"arm_r": "vial"}}],
    "flick": [
        {"t": 0.0, "set": {"arm_r": "flick_back"}}, {"t": 0.14, "set": {"arm_r": "flick"}},
        {"t": 0.7, "set": {"arm_r": "rest"}},
    ],
    "knife_draw": [{"t": 0.0, "set": {"arm_r": "knife_low"}}, {"t": 0.4, "set": {"arm_r": "knife"}}],
}
WALK_FRAME_TIME = 0.14

# Prop colours, shared by every character.
PROP_COLOURS = {
    "paper": "#ece5d6", "food": "#b87538", "phone": "#2d303b",
    "bag": "#f4f5f7", "bagband": "#3567b8", "box": "#c49660",
    "glass": "#d6eef9", "liquid": "#9cc8ff", "cork": "#9a6a3c",
    "knife": "#e2b326", "blade": "#d9dee4",
}


# ── ramps ───────────────────────────────────────────────────────────
def _toward(h, target, amt):
    d = ((target - h + 0.5) % 1.0) - 0.5
    return (h + max(-amt, min(amt, d))) % 1.0


def ramp(base, tones):
    """Palette ramp ending at the lit tone `base`. Each tone is (lightness, hue shift, saturation shift):
    negative lightness darkens by that fraction and cools the hue, positive moves toward white and warms it."""
    r, g, b, _ = hexc(base)
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    out = []
    for dl, dh, ds in tones:
        target = 0.64 if dl < 0 else 0.13
        if s < 0.06:
            h2, s2 = target, max(0.0, s + abs(ds))
        else:
            h2, s2 = _toward(h, target, dh), min(1.0, max(0.0, s + ds))
        l2 = l * (1 + dl) if dl < 0 else l + (1 - l) * dl
        rr, gg, bb = colorsys.hls_to_rgb(h2, min(1.0, max(0.0, l2)), s2)
        out.append((round(rr * 255), round(gg * 255), round(bb * 255), 255))
    return out


# ── style definitions ───────────────────────────────────────────────
INK = "#22151b"
CHIBI = dict(
    name="chibi", scale=1, outline="ink", ink=INK,
    tones=[(-0.42, 0.04, 0.0), (-0.2, 0.02, 0.0), (0, 0, 0)],
    face=(48, 86, 12.5, 12.5), neck=(48, 99), mouth=(48, 94), face_tones=(0.8, 0.5),
    hair=dict(cap=(48, 77, 14.5, 9.5), curl_r=4.2, ring=(13.5, 10.0), n=8, inner=4, fringe_y=78),
    ears=(1.8, 2.6), ear_y=88,
    torso=dict(top=98, sh_y=102, sw=12, hem=129, hw=11, neck_w=3),
    legs=dict(hip=125, foot=158, leg_w=8, gap=1, shoe_h=5, toe=2),
    shoulders=((37, 104), (59, 104)), arm=(10.5, 10.5), arm_r=(3.8, 3.4), hand_r=2.5,
    eat_hand=(-6, 6), prop_k=0.75, phone=(4, 7), shadow=(18, 2.6),
    beard=dict(y=92, side_y=86, mouth=(44, 51, 93, 95), tache=(43, 52, 91)), nose="chibi",
    lines=[(45, 79, 51)],
    eyes={
        "key": {"L": INK, "P": ("eye", 0.5), "h": "#fffaf0", "W": "#f4ece0"},
        "open": ((42, 85), ["hP", "PP", "PP", "PP"], (52, 85), ["hP", "PP", "PP", "PP"]),
        "down": ((42, 87), ["LL", "PP", "PP"], (52, 87), ["LL", "PP", "PP"]),
        "closed": ((42, 88), ["LL"], (52, 88), ["LL"]),
        "wide": ((41, 84), [".W.", "WhP", "WPP", "WPP", ".W."], (52, 84), [".W.", "hPW", "PPW", "PPW", ".W."]),
    },
    brows={
        "key": {"B": ("brow", 0.5)},
        "normal": (82, [".BBB", "BB.."]),
        "up": (80, [".BBB", "BB.."]),
        "knit": (82, ["BBB.", "..BB"]),
        "x": (40, 52),
    },
    mouths={
        "key": {"D": "#26100e", "T": "#f0e8dc", "l": ("skin", 0.1), "F": ("food", 0.6)},
        "x": 46,
        "closed": (94, [".DD."]),
        "smile": (93, ["D..D", ".DD."]),
        "chew_a": (94, [".DD."]),
        "chew_b": (93, [".DD.", "DDDD"]),
        "talk_a": (93, [".DD.", ".DD."]),
        "talk_b": (93, ["DTTD", "DDDD", ".DD."]),
        "agape": (92, [".DD.", "DTTD", "DDDD", "DFDD", ".DD."]),
        "smirk": (93, ["...D", "DDD."]),
        "whistle": (92, ["..l.", ".lDl", "..l."]),
    },
)

ADV_INK = "#2a161a"
ADVENTURE = dict(
    name="adventure", scale=1, outline="selout", ink=ADV_INK,
    tones=[(-0.68, 0.1, 0.03), (-0.45, 0.06, 0.02), (-0.2, 0.03, 0.01), (0, 0, 0)],
    face=(48, 52, 7.5, 9.5), neck=(48, 62), mouth=(48, 58), face_tones=(0.8, 0.55),
    hair=dict(cap=(48, 44.5, 8.6, 6.0), curl_r=2.8, ring=(8.0, 6.6), n=9, inner=3, fringe_y=45),
    ears=(1.2, 2.2), ear_y=53,
    torso=dict(top=61, sh_y=66, sw=14, hem=105, hw=12, neck_w=3),
    legs=dict(hip=100, foot=158, leg_w=7, gap=1, shoe_h=5, toe=4),
    shoulders=((36, 69), (60, 69)), arm=(17.5, 17.0), arm_r=(3.6, 3.2), hand_r=2.6,
    eat_hand=(-10, 11), prop_k=0.9, phone=(5, 9), shadow=(22, 3.0),
    beard=dict(y=56, side_y=51, mouth=(45, 50, 57, 58), tache=(45, 50, 56)), nose="adventure",
    lines=[(45, 46, 50)],
    eyes={
        "key": {"L": ADV_INK, "P": ("eye", 0.5), "W": "#e9e3d6", "s": ("skin", 0.3)},
        "open": ((44, 51), ["LL", "WP"], (50, 51), ["LL", "PW"]),
        "down": ((44, 51), ["ss", "LL"], (50, 51), ["ss", "LL"]),
        "closed": ((44, 52), ["LL"], (50, 52), ["LL"]),
        "wide": ((44, 50), ["WW", "WP", "WW"], (50, 50), ["WW", "PW", "WW"]),
    },
    brows={
        "key": {"B": ("brow", 0.5)},
        "normal": (49, ["BBB"]),
        "up": (48, [".BB", "B.."]),
        "knit": (48, ["BB.", "..B"]),
        "x": (43, 50),
    },
    mouths={
        "key": {"D": "#2e1416", "T": "#e9e3d6", "l": ("skin", 0.3), "F": ("food", 0.6)},
        "x": 46,
        "closed": (57, ["DDDD"]),
        "smile": (57, ["D..D", ".DD."]),
        "chew_a": (57, [".DD."]),
        "chew_b": (57, [".DD.", ".ll."]),
        "talk_a": (57, [".DD.", ".DD."]),
        "talk_b": (57, ["DTTD", ".DD."]),
        "agape": (57, ["DTTD", "DDDD", "DFDD", ".DD."]),
        "smirk": (57, ["...D", "DDD."]),
        "whistle": (57, ["..D.", ".lDl"]),
    },
)

BLACK = "#000000"
RETRO = dict(
    name="retro", scale=2, outline="ink", ink=BLACK,
    tones=[(-0.38, 0.02, 0.04), (0, 0, 0.06)],
    face=(24, 30, 5.8, 6.2), neck=(24, 37), mouth=(24, 34), face_tones=(0.8, 0.3),
    hair=dict(cap=(24, 25.5, 6.8, 4.2), curl_r=1.9, ring=(6.2, 4.6), n=7, inner=2, fringe_y=26),
    ears=(0.9, 1.4), ear_y=31,
    torso=dict(top=36, sh_y=39, sw=7, hem=57, hw=6, neck_w=2),
    legs=dict(hip=55, foot=78, leg_w=4, gap=0, shoe_h=3, toe=1),
    shoulders=((17.5, 40.5), (30.5, 40.5)), arm=(8.0, 8.0), arm_r=(2.1, 1.9), hand_r=1.4,
    eat_hand=(-3.5, 3.5), prop_k=0.42, phone=(2, 4), shadow=(10, 1.4),
    beard=dict(y=34, side_y=30, side=1.6, mouth=(22, 25, 34, 35), tache=(22, 25, 33)), nose="retro",
    glasses_bars=True,
    lines=[(22, 27, 25)],
    eyes={
        "key": {"P": ("eye", 0.5), "W": "#fcfcfc", "s": ("skin", 0.0)},
        "open": ((21, 30), ["P", "P"], (26, 30), ["P", "P"]),
        "down": ((21, 31), ["P"], (26, 31), ["P"]),
        "closed": ((21, 31), ["s"], (26, 31), ["s"]),
        "wide": ((20, 29), ["WP", "WP"], (26, 29), ["PW", "PW"]),
    },
    brows={
        "key": {"B": ("brow", 0.5)},
        "normal": (28, ["BB"]),
        "up": (27, ["BB"]),
        "knit": (28, ["B.", ".B"]),
        "x": (20, 26),
    },
    mouths={
        "key": {"D": "#2a0e08", "T": "#fcfcfc", "l": ("skin", 0.0), "F": ("food", 0.6)},
        "x": 22,
        "closed": (34, [".DD."]),
        "smile": (34, ["D..D", ".DD."]),
        "chew_a": (34, ["..DD"]),
        "chew_b": (34, ["DD.."]),
        "talk_a": (34, [".DD.", ".DD."]),
        "talk_b": (34, ["DDDD", ".DD."]),
        "agape": (33, [".DD.", "DTTD", "DFDD", ".DD."]),
        "smirk": (34, ["...D", "DDD."]),
        "whistle": (33, ["..D.", ".DlD", "..D."]),
    },
)

MINIMAL = dict(
    name="minimal", scale=3, outline="none", ink=None,
    tones=[(-0.3, 0.02, 0.0), (0, 0, 0)],
    face=(16, 22.5, 3.3, 3.6), neck=(16, 27), mouth=(16, 24.5), face_tones=(0.8, 0.8),
    hair=dict(cap=(16, 20.5, 3.9, 2.6), curl_r=1.25, ring=(3.3, 2.3), n=6, inner=1, fringe_y=19),
    ears=(0.7, 1.0), ear_y=23,
    torso=dict(top=27, sh_y=28, sw=4.6, hem=38, hw=4.0, neck_w=1),
    legs=dict(hip=37, foot=52, leg_w=2, gap=1, shoe_h=1, toe=1),
    shoulders=((11.6, 29), (20.4, 29)), arm=(4.8, 4.8), arm_r=(1.15, 1.0), hand_r=0.9,
    eat_hand=(-2, 2), prop_k=0.32, phone=(1, 2), shadow=(14, 2.0), vial_min=3.0,
    beard=dict(y=25, side_y=22, side=1.0, mouth=(15, 17, 24, 24), tache=None), nose="none",
    glasses_bars=True, trims=False,
    lines=[(15, 20, 17)],
    eyes={
        "key": {"P": ("eye", 0.5), "s": ("skin", 0.0)},
        "open": ((14, 22), ["P"], (17, 22), ["P"]),
        "down": ((14, 23), ["P"], (17, 23), ["P"]),
        "closed": ((14, 22), ["s"], (17, 22), ["s"]),
        "wide": ((14, 21), ["P", "P"], (17, 21), ["P", "P"]),
    },
    brows={
        "key": {"B": ("brow", 0.5)},
        "normal": (20, ["B"]),
        "up": (19, ["B"]),
        "knit": (20, [".B"]),
        "x": (14, 17),
    },
    mouths={
        "key": {"D": "#2a1410", "T": "#f4efe6", "l": ("skin", 0.0), "F": ("food", 0.6)},
        "x": 15,
        "closed": (24, [".D."]),
        "smile": (24, [".DD"]),
        "chew_a": (24, [".D."]),
        "chew_b": (24, ["DD."]),
        "talk_a": (24, [".D.", ".D."]),
        "talk_b": (24, ["DDD"]),
        "agape": (23, [".D.", "DTD", ".D."]),
        "smirk": (24, ["..D", "DD."]),
        "whistle": (24, ["lDl"]),
    },
)

MINIMAL_PLUS = dict(
    name="minimal_plus", scale=2, outline="selout", ink=None,
    tones=[(-0.4, 0.04, 0.0), (-0.18, 0.02, 0.0), (0, 0, 0)],
    face=(24, 29.5, 4.6, 5.0), neck=(24, 36), mouth=(24, 33), face_tones=(0.8, 0.55),
    hair=dict(cap=(24, 26, 5.4, 3.4), curl_r=1.6, ring=(4.6, 3.4), n=7, inner=2, fringe_y=25),
    ears=(0.8, 1.2), ear_y=30,
    torso=dict(top=36, sh_y=37.5, sw=6.8, hem=54, hw=5.8, neck_w=1.5),
    legs=dict(hip=53, foot=78, leg_w=3, gap=1, shoe_h=2, toe=1),
    shoulders=((17.4, 38.5), (30.6, 38.5)), arm=(7.6, 7.6), arm_r=(1.6, 1.4), hand_r=1.2,
    eat_hand=(-3, 3), prop_k=0.45, phone=(2, 3), shadow=(16, 2.2), vial_min=3.5,
    beard=dict(y=33, side_y=29, side=1.4, mouth=(23, 25, 33, 33), tache=(22, 26, 32)), nose="retro",
    glasses_bars=True,
    lines=[(22, 26, 26)],
    eyes={
        "key": {"P": ("eye", 0.5), "W": "#f4efe6", "s": ("skin", 0.0)},
        "open": ((22, 28), ["P", "P"], (26, 28), ["P", "P"]),
        "down": ((22, 29), ["P"], (26, 29), ["P"]),
        "closed": ((22, 29), ["s"], (26, 29), ["s"]),
        "wide": ((21, 28), ["WP", "WP"], (26, 28), ["PW", "PW"]),
    },
    brows={
        "key": {"B": ("brow", 0.5)},
        "normal": (26, ["BB"]),
        "up": (25, ["BB"]),
        "knit": (26, ["B.", ".B"]),
        "x": (21, 26),
    },
    mouths={
        "key": {"D": "#2a1410", "T": "#f4efe6", "l": ("skin", 0.0), "F": ("food", 0.6)},
        "x": 22,
        "closed": (33, [".DD."]),
        "smile": (32, ["D..D", ".DD."]),
        "chew_a": (33, ["..DD"]),
        "chew_b": (33, ["DD.."]),
        "talk_a": (33, [".DD.", ".DD."]),
        "talk_b": (33, ["DDDD", ".DD."]),
        "agape": (32, [".DD.", "DTTD", "DDDD"]),
        "smirk": (32, ["...D", "DDD."]),
        "whistle": (32, ["..D.", ".DlD", "..D."]),
    },
)

STYLES = {"chibi": CHIBI, "adventure": ADVENTURE, "retro": RETRO, "minimal": MINIMAL, "minimal_plus": MINIMAL_PLUS}


# ── style + character → drawing spec ────────────────────────────────
def spec(style, char):
    """The style dict plus the character's materials and build offsets."""
    st = dict(style)
    st["char"] = char
    outline = style["ink"] if style["outline"] == "ink" else None
    tones = style["tones"]
    fit = char["outfit"]
    colours = dict(PROP_COLOURS)
    colours.update({
        "skin": char["skin"], "hair": char["hair"]["colour"],
        "top": fit["top"]["colour"], "under": fit["under"]["colour"],
        "trousers": fit["trousers"], "shoe": fit["shoes"], "sole": fit["soles"],
    })
    if char.get("facial_hair"):
        colours["beard"] = char["facial_hair"]["colour"]
    mats = {k: Material(ramp(c, tones), outline=outline) for k, c in colours.items()}
    mats["collar"] = Material(ramp(colours["top"], [(t[0] * 0.8 + 0.1, t[1], t[2]) for t in tones]), outline=outline)
    mats["eye"] = Material([char["eyes"]], outline=outline)
    brow = char.get("brows") or "#%02x%02x%02x" % darken(hexc(colours["hair"]), 0.6)[:3]
    mats["brow"] = Material([brow], outline=outline)
    if char.get("glasses"):
        mats["frame"] = Material([darken(hexc(char["glasses"]), 0.7), hexc(char["glasses"])], outline=outline)
    st["mats"] = mats
    st["sleeve"] = "under" if fit["top"]["kind"] == "waistcoat" else "top"

    b = char["build"]
    g = style["legs"]
    leg_len = g["foot"] - g["hip"]
    st["dy_body"] = -round(leg_len * (b["height"] - 1.0))
    st["dy_head"] = st["dy_body"] + b["stoop"]
    wk = b["width"]
    t = dict(style["torso"])
    t["sw"] = style["torso"]["sw"] * wk
    t["hw"] = style["torso"]["hw"] * wk
    t["sh_y"] = style["torso"]["sh_y"] + b["stoop"] * 0.5
    st["torso"] = t
    spread = (t["sw"] - style["torso"]["sw"])
    (lx, ly), (rx, ry) = style["shoulders"]
    tuck = TURN * t["sw"] * 0.35
    st["shoulders"] = ((lx - spread, ly + b["stoop"] * 0.5), (rx + spread - tuck, ry + b["stoop"] * 0.5))
    st["fdx"] = max(1, round(TURN * style["face"][2] * 0.5))
    st["front"] = max(1, round(TURN * t["sw"] * 0.7))
    st["far_in"] = round(TURN * t["sw"] * 0.25)
    lg = dict(g)
    lg["hip"] = g["hip"] + st["dy_body"]
    st["legs"] = lg
    st["leg_len"] = leg_len
    return st


# ── canvas with style-aware outline ─────────────────────────────────
class StyleCanvas(Canvas):
    def __init__(self, st):
        s = st["scale"]
        super().__init__(W // s, H // s, st["mats"])
        self.style = st

    def finish(self, outline=True, dy=0, dx=0):
        if self.style["outline"] == "none":
            outline = False
        if outline and self.style["outline"] == "selout":
            img = self._render_selout()
        else:
            img = self.render(outline=outline)
        if dx or dy:
            moved = Image.new("RGBA", img.size, (0, 0, 0, 0))
            moved.alpha_composite(img, (max(0, dx), max(0, dy)), (max(0, -dx), max(0, -dy)))
            img = moved
        s = self.style["scale"]
        return img.resize((W, H), Image.NEAREST) if s != 1 else img

    def _render_selout(self):
        """Outline in each material's own darkest tone; one step lighter on the lit (upper-left) side."""
        img = self.render(outline=False)
        out = img.load()
        for y in range(self.h):
            for x in range(self.w):
                if self.mat[y][x] is not None:
                    continue
                best = None
                for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + ddx, y + ddy
                    if not (0 <= nx < self.w and 0 <= ny < self.h) or self.mat[ny][nx] is None:
                        continue
                    m = self.mat[ny][nx]
                    if m == "_fixed":
                        c = darken(self.fixed[ny][nx], 0.5)
                    else:
                        ramp_ = self.materials[m].ramp
                        lit = ddx == 1 or ddy == 1
                        c = ramp_[0] if lit else darken(ramp_[0], 0.62)
                    if best is None or sum(c[:3]) < sum(best[:3]):
                        best = c
                if best is not None:
                    out[x, y] = best
        return img


def _in_ell(x, y, e):
    cx, cy, rx, ry = e
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


# ── legs + shadow ───────────────────────────────────────────────────
def legs_canvas(st, pose=((0, 0), (0, 0))):
    """Legs with each foot offset by (dx, lift) in stride/lift units. Both feet point right;
    the far (viewer-right) leg draws first so the near leg stays in front."""
    c = StyleCanvas(st)
    g = st["legs"]
    cx = c.w // 2
    hip, foot, lw, gap, sh, toe = g["hip"], g["foot"], g["leg_w"], g["gap"], g["shoe_h"], g["toe"]
    stride = max(1, round(st["leg_len"] * 0.13))
    lift = max(1, round(st["leg_len"] * 0.08))
    half = gap / 2.0
    back = max(1, round(lift * 0.4))  # far foot stands a little behind

    def leg(side, dx_u, lift_u):
        dx, up = round(dx_u * stride), round(lift_u * lift)
        f = foot - up - (back if side == "r" else 0)
        ankle = f - sh
        if side == "l":
            x0, x1 = cx - half - lw, cx - half
            c.poly([(x0 - 0.5, hip), (x1, hip), (x1 + dx, ankle + 1), (x0 + 0.5 + dx, ankle + 1)], "trousers", base=0.9, peak=0.3)
            a, b = x0 + dx, x1 + dx
            c.poly([(a, ankle), (b - 0.5, ankle), (b + toe, f - 1.5), (b + toe, f), (a, f)], "shoe", base=1.0, peak=0.35)
            xs = range(int(a), int(b + toe))
        else:
            x0, x1 = cx + half - st["far_in"], cx + half + lw - st["far_in"]
            c.poly([(x0, hip), (x1 + 0.5, hip), (x1 - 0.5 + dx, ankle + 1), (x0 + dx, ankle + 1)], "trousers", base=0.6, peak=0.35)
            a, b = x0 + dx, x1 + dx
            c.poly([(a, ankle), (b - 0.5, ankle), (b + toe, f - 1.5), (b + toe, f), (a, f)], "shoe", base=0.9, peak=0.4)
            xs = range(int(a), int(b + toe))
        for x in xs:
            c.shade_px(x, f - 1, "sole", 0.6)

    (ldx, llift), (rdx, rlift) = pose
    leg("r", rdx, rlift)
    leg("l", ldx, llift)
    return c


def shadow(st):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    p = img.load()
    cx, cy = ORIGIN
    rx, ry = st["shadow"]
    rx *= st["char"]["build"]["width"]
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if d <= 1.0 and 0 <= y < H:
                p[x, y] = (12, 8, 10, 110 if d < 0.55 else 60)
    return img


# ── torso ───────────────────────────────────────────────────────────
def torso_canvas(st):
    c = StyleCanvas(st)
    t = st["torso"]
    dy = st["dy_body"]
    mid = c.w / 2.0
    top, shy, sw, hem, hw, nw = t["top"] + dy, t["sh_y"] + dy, t["sw"], t["hem"] + dy, t["hw"], t["neck_w"]
    kind = st["char"]["outfit"]["top"]["kind"]
    under = st["char"]["outfit"]["under"]["kind"]
    far = st["far_in"]
    body = [(mid - nw - 1, top + 1), (mid - sw + 2, shy - 1), (mid - sw, shy + 2), (mid - hw, hem), (mid + hw - far, hem),
            (mid + sw - far, shy + 2), (mid + sw - far - 2, shy - 1), (mid + nw + 1, top + 1)]
    c.poly(body, "under" if kind == "waistcoat" else "top", base=0.85, peak=0.3)
    c.rect(int(mid - nw), int(top - 3), int(mid + nw - 1), int(top + 1), "skin", 0.3)
    cx = mid + st["front"]  # the clothes' front line
    left, right = mid - sw, mid + sw - far  # outer edges at the shoulder
    lhem, rhem = mid - hw, mid + hw - far
    tw = max(1, round(sw * 0.26))
    cl = max(2, round(sw * 0.35))
    if kind == "jacket":
        tee = [(cx - tw + 0.5, top + 1), (cx + tw - 0.5, top + 1), (cx + tw, hem), (cx - tw, hem)]
        c.poly(tee, "under", base=1.0, peak=0.4)
        c.poly([(cx - tw, top), (cx - tw + 1, top + cl + 1), (cx - tw - cl, top + cl - 1), (mid - nw - 1, top)], "collar", base=1.0, cyl=False)
        c.poly([(cx + tw, top), (cx + tw - 1, top + cl + 1), (cx + tw + cl, top + cl - 1), (mid + nw + 1, top)], "collar", base=0.55, cyl=False)
        if st.get("trims", True):
            bx = int(cx - tw - 1)
            step = max(3, (hem - top) // 5)
            for y in range(int(top + cl + 3), int(hem - 2), step):
                c.shade_px(bx, y, "top", 0.0)
            _pocket(c, int(cx + tw + 2), int(right - 2), int(shy + 3), max(3, round((hem - top) * 0.22)))
    elif kind == "jumper":
        for x in range(int(mid - nw - 1), int(mid + nw + 1)):
            c.shade_px(x, int(top + 1), "top", 0.15)
        if under == "shirt":
            _shirt_collar(c, mid, top, nw, cl)
        for x in range(int(lhem), int(rhem)):
            c.shade_px(x, int(hem - 1), "top", 0.2)
    else:  # waistcoat over the shirt
        vy = top + (hem - top) * 0.42
        lv = [(mid - nw - 1, top + 1), (cx - 0.5, vy), (cx - 0.5, hem + 1.5), (lhem, hem), (left + 1.5, shy + 3),
              (left + 3, shy - 0.5)]
        rv = [(mid + nw + 1, top + 1), (right - 3, shy - 0.5), (right - 1.5, shy + 3), (rhem, hem),
              (cx + 0.5, hem + 1.5), (cx + 0.5, vy)]
        c.poly(lv, "top", base=0.95, peak=0.4)
        c.poly(rv, "top", base=0.6, peak=0.4)
        step = max(2, round((hem - vy) / 4))
        for y in range(int(vy + 2), int(hem), step):
            c.shade_px(int(cx), y, "collar", 1.0)
        _shirt_collar(c, mid, top, nw, cl)
    return c


def _pocket(c, x0, x1, y0, h):
    if x1 - x0 < 3:
        return
    for x in range(x0, x1 + 1):
        c.shade_px(x, y0, "top", 0.0)
        c.shade_px(x, y0 + h, "top", 0.0)
    for y in range(y0, y0 + h + 1):
        c.shade_px(x0, y, "top", 0.0)
        c.shade_px(x1, y, "top", 0.0)


def _shirt_collar(c, cx, top, nw, cl):
    c.poly([(cx - 0.5, top + 1), (cx - 0.5, top + cl), (cx - nw - cl * 0.6, top + cl - 1), (cx - nw - 1, top)], "under", base=1.1, cyl=False)
    c.poly([(cx + 0.5, top + 1), (cx + nw + 1, top), (cx + nw + cl * 0.6, top + cl - 1), (cx + 0.5, top + cl)], "under", base=0.7, cyl=False)


# ── head ────────────────────────────────────────────────────────────
def hair_curls(st):
    h = st["hair"]
    hx, hy, _, _ = h["cap"]
    hx -= st["fdx"] * 0.5
    rx, ry = h["ring"]
    r = h["curl_r"]
    curls = []
    n = h["n"]
    for i in range(n):
        a = math.radians(172 - 164 * i / (n - 1))  # from left-low over the top to right-low
        curls.append((hx + rx * math.cos(a), hy - ry * math.sin(a) * 0.95, r))
    for i in range(h["inner"]):
        t = (i + 0.5) / h["inner"]
        curls.append((hx - rx * 0.6 + rx * 1.2 * t, hy - ry * 0.35, r * 1.1))
    return curls


def _texture_curls(c, curls):
    """A dark hook under each curl, a lit tuft on top."""
    for (cx, cy, r) in curls:
        for deg in range(10, 150, 12):
            a = math.radians(deg)
            x, y = int(cx + r * 0.7 * math.cos(a)), int(cy + r * 0.62 * math.sin(a))
            if 0 <= y < c.h and 0 <= x < c.w and c.mat[y][x] == "hair":
                c.shade_px(x, y, "hair", 0.05)
        x, y = int(cx - r * 0.3), int(cy - r * 0.45)
        if 0 <= y < c.h and 0 <= x < c.w and c.mat[y][x] == "hair":
            c.shade_px(x, y, "hair", 1.0)


def _fill_holes(c, mat, v):
    for _ in range(2):
        holes = [(x, y) for y in range(1, c.h - 1) for x in range(1, c.w - 1)
                 if c.mat[y][x] is None and sum(c.mat[y + dy][x + dx] is not None for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))) >= 3]
        for (x, y) in holes:
            c.shade_px(x, y, mat, v)


def head(st):
    c = StyleCanvas(st)
    char = st["char"]
    hair = char["hair"]
    face = st["face"]
    fx, fy, frx, fry = face
    erx, ery = st["ears"]
    lit, shade = st["face_tones"]
    hx, hy, hrx, hry = st["hair"]["cap"]
    hx -= st["fdx"] * 0.5
    if hair["kind"] == "thinning":
        c.ellipse(hx, hy + hry * 0.3, hrx * 0.85, hry * 0.95, "skin", base=0.85)
    else:
        c.ellipse(hx, hy, hrx, hry, "hair", base=0.6)
    c.ellipse(fx, fy, frx, fry, "skin", base=lit, flat=True)
    for y in range(c.h):
        for x in range(c.w):
            if _in_ell(x, y, face) and x + 0.5 > fx + frx * 0.55:
                c.shade_px(x, y, "skin", shade)
    if char.get("facial_hair"):
        facial_hair(c, st, char["facial_hair"]["kind"])
    # near ear, set in from the back of the head by the turn
    ex = fx - frx * (1 - 0.9 * TURN)
    c.ellipse(ex, st["ear_y"], erx, ery, "skin", base=0.5)
    if erx >= 1:
        c.shade_px(int(ex), int(st["ear_y"]), "skin", 0.1)
    nose(c, st)
    if char.get("lines"):
        for (x0, y, x1) in st["lines"]:
            for x in range(x0 + st["fdx"], x1 + st["fdx"] + 1, 2):
                c.shade_px(x, y, "skin", 0.45)
    {"curly": hair_curly, "short": hair_short, "thinning": hair_thinning}[hair["kind"]](c, st, lit, shade)
    return c.finish(dy=st["dy_head"])


def facial_hair(c, st, kind):
    fx, fy, frx, fry = st["face"]
    face = st["face"]
    b = st["beard"]
    d = st["fdx"]
    mx0, mx1, my0, my1 = b["mouth"]
    mx0, mx1 = mx0 + d, mx1 + d
    tx0, tx1, ty = b["tache"] or (0, -1, -1)
    tx0, tx1 = tx0 + d, tx1 + d
    side_w = b.get("side", 2.5)
    for y in range(c.h):
        for x in range(c.w):
            if not _in_ell(x, y, face):
                continue
            right = x + 0.5 > fx + d
            in_mouth = mx0 <= x <= mx1 and my0 <= y <= my1
            if kind in ("beard", "stubble"):
                off = x + 0.5 - fx
                side = off <= -(frx - side_w * 1.5) or off >= frx - side_w * 0.6
                if kind == "beard" and (y >= b["y"] or (side and y >= b["side_y"])) and not in_mouth:
                    c.shade_px(x, y, "beard", 0.9 - 0.25 * right)
                elif kind == "stubble" and y > b["y"] and not in_mouth and (x + y) % 2 == 0:
                    c.shade_px(x, y, "skin", 0.45)
            if kind in ("beard", "moustache") and y == ty and tx0 <= x <= tx1:
                c.shade_px(x, y, "beard", 0.75 - 0.25 * right)
    if kind == "beard":
        for x in range(int(fx + d - frx * 0.55), int(fx + d + frx * 0.55) + 1):
            c.shade_px(x, int(fy + fry), "beard", 0.4)


def hair_curly(c, st, lit, shade):
    fx, fy, frx, fry = st["face"]
    face = st["face"]
    curls = hair_curls(st)
    for (cx, cy, r) in curls:
        c.ellipse(cx, cy, r, r * 0.92, "hair", base=1.1)
    _texture_curls(c, curls)
    _fill_holes(c, "hair", 0.45)
    # hairline: forehead clear below the fringe
    fringe = st["hair"]["fringe_y"]
    hairline = fx + st["fdx"] * 0.5
    for y in range(int(fringe), int(fy)):
        for x in range(c.w):
            if _in_ell(x, y, face) and c.mat[y][x] == "hair" and abs(x + 0.5 - hairline) < frx - 1.2:
                if not (y == int(fringe) and (x % 3 == 0)):
                    c.shade_px(x, y, "skin", lit if x + 0.5 <= fx + frx * 0.55 else shade)
    if st["char"]["hair"].get("lock"):
        r = st["hair"]["curl_r"]
        lx, ly = fx + st["fdx"] - frx * 0.22, fringe + r * 0.35
        c.ellipse(lx, ly, r * 0.55, r * 0.7, "hair", base=0.9)
        c.shade_px(int(lx + r * 0.3), int(ly + r * 0.55), "hair", 0.05)


def hair_short(c, st, lit, shade):
    fx, fy, frx, fry = st["face"]
    fringe = st["hair"]["fringe_y"] + 1
    hx, hy, hrx, hry = st["hair"]["cap"]
    face = (fx, fy, frx, fry)
    c.ellipse(hx, hy + 1, hrx * 0.92, hry * 0.9, "hair", base=0.95, clip=lambda x, y: y <= fringe or not _in_ell(x, y, face))
    for y in range(int(hy), int(fringe) + 1):
        for x in range(c.w):
            if _in_ell(x, y, (fx, fy, frx + 0.6, fry + 0.6)):
                c.shade_px(x, y, "hair", 0.9 if x + 0.5 <= fx else 0.5)
    for x in range(int(fx - frx), int(fx + frx) + 1, 3):
        c.shade_px(x, int(hy), "hair", 1.0)


def hair_thinning(c, st, lit, shade):
    fx, fy, frx, fry = st["face"]
    h = st["hair"]
    hx, hy, _, _ = h["cap"]
    rx, ry = h["ring"]
    r = h["curl_r"] * 0.9
    tufts = []
    for deg in (200, 180, 160, 140, -20, 0, 20, 40):
        a = math.radians(deg)
        tufts.append((hx + rx * 1.05 * math.cos(a), hy + ry * 0.75 - ry * 0.95 * math.sin(a), r))
    for (cx, cy, rr) in tufts:
        c.ellipse(cx, cy, rr, rr * 0.85, "hair", base=1.0)
    _texture_curls(c, tufts)
    # wisps across the bare crown
    top = hy - ry * 0.75
    for i, x in enumerate(range(int(hx - rx * 0.5), int(hx + rx * 0.6), 2)):
        c.shade_px(x, int(top + (i % 2)), "hair", 0.9)


def nose(c, st):
    fx, fy, _, _ = st["face"]
    x = int(fx) + st["fdx"]
    kind = st["nose"]
    if kind == "none":
        return
    if kind == "chibi":
        c.shade_px(x, int(fy + 4), "skin", 0.3)
    elif kind == "adventure":
        for y in range(int(fy), int(fy + 4)):
            c.shade_px(x - 1, y, "skin", 0.95)
            c.shade_px(x, y, "skin", 0.55)
        c.shade_px(x - 2, int(fy + 4), "skin", 0.2)
        c.shade_px(x - 1, int(fy + 4), "skin", 0.45)
        c.shade_px(x, int(fy + 4), "skin", 0.2)
        c.shade_px(x + 1, int(fy + 3), "skin", 0.3)
    else:
        c.shade_px(x, int(fy + 2), "skin", 0.2)


# ── face overlays ───────────────────────────────────────────────────
def overlay_eyes(st, frame):
    c = StyleCanvas(st)
    e = st["eyes"]
    (lx, ly), lrows, (rx, ry), rrows = e[frame]
    c.stamp(lx, ly, lrows, e["key"])
    c.stamp(rx, ry, rrows, e["key"])
    return c.finish(outline=False, dy=st["dy_head"], dx=st["fdx"])


def overlay_brows(st, frame):
    c = StyleCanvas(st)
    b = st["brows"]
    lx, rx = b["x"]
    yl, rl = b["normal" if frame == "quirk" else frame]
    yr, rr = b["up" if frame == "quirk" else frame]
    c.stamp(lx, yl, rl, b["key"])
    c.stamp(rx, yr, [row[::-1] for row in rr], b["key"])
    return c.finish(outline=False, dy=st["dy_head"], dx=st["fdx"])


def overlay_mouth(st, frame):
    c = StyleCanvas(st)
    m = st["mouths"]
    if frame == "closed" and st["char"].get("expression") == "smile":
        frame = "smile"
    y, rows = m[frame]
    c.stamp(m["x"], y, rows, m["key"])
    return c.finish(outline=False, dy=st["dy_head"], dx=st["fdx"])


def overlay_glasses(st):
    """Rims round each open eye plus a bridge, from the open-eye stamps; at half resolution
    only the top bar and bridge, so one-pixel eyes stay visible."""
    c = StyleCanvas(st)
    (lx, ly), lrows, (rx, ry), rrows = st["eyes"]["open"]
    boxes = []
    for (x, y, rows) in ((lx, ly, lrows), (rx, ry, rrows)):
        w, h = len(rows[0]), len(rows)
        x0, y0, x1, y1 = x - 1, y - 1, x + w, y + h
        for xx in range(x0, x1 + 1):
            c.shade_px(xx, y0, "frame", 0.8)
            c.shade_px(xx, y1, "frame", 0.3)
        if st.get("glasses_bars"):
            for xx in range(x0, x1 + 1):
                c.clear(xx, y1)
        else:
            for yy in range(y0, y1 + 1):
                c.shade_px(x0, yy, "frame", 0.6)
                c.shade_px(x1, yy, "frame", 0.6)
        boxes.append((x0, x1, y0))
    for xx in range(boxes[0][1] + 1, boxes[1][0]):
        c.shade_px(xx, boxes[0][2] + 1, "frame", 0.6)
    return c.finish(outline=False, dy=st["dy_head"], dx=st["fdx"])


# ── arms ────────────────────────────────────────────────────────────
def solve_elbow(s, h, a, b, hint):
    dx, dy = h[0] - s[0], h[1] - s[1]
    d = math.hypot(dx, dy) or 1e-6
    dc = min(a + b - 0.01, max(abs(a - b) + 0.01, d))
    ux, uy = dx / d, dy / d
    h = (s[0] + ux * dc, s[1] + uy * dc)
    cos_a = (a * a + dc * dc - b * b) / (2 * a * dc)
    al = math.acos(max(-1.0, min(1.0, cos_a)))
    best = None
    for sgn in (1, -1):
        ca, sa = math.cos(sgn * al), math.sin(sgn * al)
        e = (s[0] + a * (ux * ca - uy * sa), s[1] + a * (ux * sa + uy * ca))
        dist = math.hypot(e[0] - hint[0], e[1] - hint[1])
        if best is None or dist < best[0]:
            best = (dist, e)
    return best[1], h


def arm_pose(st, side, frame):
    shoulder = st["shoulders"][0 if side == "l" else 1]
    shoulder = (shoulder[0], shoulder[1] + st["dy_body"])
    a, b = st["arm"]
    k = (a + b) / 38.0
    rel, hint, prop = (POSE_L if side == "l" else POSE_R)[frame]
    if rel is None:
        mx, my = st["mouth"]
        target = (mx + st["eat_hand"][0], my + st["dy_head"] + st["eat_hand"][1])
    else:
        target = (shoulder[0] + rel[0] * k, shoulder[1] + rel[1] * k)
    hint_pt = (shoulder[0] + hint[0] * k, shoulder[1] + hint[1] * k)
    elbow, hand = solve_elbow(shoulder, target, a, b, hint_pt)
    return shoulder, elbow, hand, prop


def wrap(c, st, hx, hy, angle_deg):
    k = st["prop_k"]
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    tip = (hx + dx * 8.5 * k, hy + dy * 8.5 * k)
    base = (hx - dx * 2.0 * k, hy - dy * 2.0 * k)
    c.capsule(base, tip, max(1.0, 2.2 * k), max(1.2, 3.0 * k), "paper", base=1.0)
    c.ellipse(tip[0] + dx * 0.8 * k, tip[1] + dy * 0.8 * k, max(1.2, 2.6 * k), max(1.1, 2.3 * k), "food", base=1.05)


def bag(c, st, hx, hy, swing_deg):
    """Plastic carrier hanging from the hand: handles up to the fist, white body squared off
    by the box inside, a blue band, the flaps of the opened cardboard box poking out of the mouth."""
    L = st["leg_len"]
    bw, bh = L * 0.16, L * 0.36
    top = max(2.0, L * 0.11)
    a = math.radians(swing_deg)
    ca, sa = math.cos(a), math.sin(a)

    def P(x, y):
        return (hx + x * ca - y * sa, hy + x * sa + y * ca)

    hr = max(0.5, L * 0.018)
    c.capsule(P(-0.6, 0), P(-bw * 0.7, top + 0.5), hr, hr, "bag", base=0.75)
    c.capsule(P(0.6, 0), P(bw * 0.7, top + 0.5), hr, hr, "bag", base=0.55)
    fh = bw * 0.75
    c.poly([P(-bw * 0.95, top - fh), P(-bw * 0.15, top - fh * 0.35), P(-bw * 0.1, top + 1), P(-bw * 0.9, top + 1)], "box", base=1.0, cyl=False)
    c.poly([P(bw * 0.1, top - fh * 0.3), P(bw * 1.0, top - fh * 0.9), P(bw * 0.95, top + 1), P(bw * 0.15, top + 1)], "box", base=0.5, cyl=False)
    body = [P(-bw, top), P(bw, top), P(bw * 1.05, top + bh * 0.85), P(bw * 0.85, top + bh), P(-bw * 0.85, top + bh),
            P(-bw * 1.05, top + bh * 0.85)]
    c.poly(body, "bag", base=1.0, peak=0.25)
    band_y = top + bh * 0.3
    band = max(1.0, bh * 0.09)
    c.poly([P(-bw * 1.02, band_y), P(bw * 1.02, band_y), P(bw * 1.03, band_y + band), P(-bw * 1.03, band_y + band)],
           "bagband", base=1.0, peak=0.3)
    # creases where the plastic pulls over the box corners
    for (x, y0, y1) in ((-bw * 0.45, top + bh * 0.55, top + bh * 0.9), (bw * 0.5, top + bh * 0.5, top + bh * 0.8)):
        for i in range(int(y1 - y0) + 1):
            px, py = P(x, y0 + i)
            c.shade_px(int(px), int(py), "bag", 0.3)


def vial(c, st, hx, hy, angle_deg):
    k = st["prop_k"]
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    ln = max(st.get("vial_min", 4.0), 8.0 * k)
    r = max(1.0, 1.7 * k)
    base = (hx + dx * 0.5, hy + dy * 0.5)
    tip = (hx + dx * ln, hy + dy * ln)
    c.capsule(base, tip, r, r, "glass", base=1.0)
    mid = (hx + dx * ln * 0.6, hy + dy * ln * 0.6)
    c.capsule(base, mid, max(0.6, r - 0.5), max(0.6, r - 0.5), "liquid", base=1.1)
    c.shade_px(int(tip[0]), int(tip[1]), "cork", 0.7)
    return (round(tip[0], 1), round(tip[1], 1))


def knife(c, st, hx, hy, angle_deg):
    """Stanley knife: yellow handle in the fist, short trapezoid blade out of its front end."""
    k = st["prop_k"]
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    r = max(0.9, 1.5 * k)
    tail = (hx - dx * 2.0 * k, hy - dy * 2.0 * k)
    nose_ = (hx + dx * max(2.0, 4.0 * k), hy + dy * max(2.0, 4.0 * k))
    tip = (nose_[0] + dx * max(1.5, 3.5 * k), nose_[1] + dy * max(1.5, 3.5 * k))
    c.capsule(nose_, tip, max(0.6, r * 0.8), max(0.5, r * 0.4), "blade", base=1.1)
    c.capsule(tail, nose_, r, r, "knife", base=1.0)


def _sleeve_cuff(c, st, elbow, wrist, base):
    fx, fy = wrist[0] - elbow[0], wrist[1] - elbow[1]
    p0 = (elbow[0] + fx * 0.7, elbow[1] + fy * 0.7)
    rf = st["arm_r"][1]
    c.capsule(p0, wrist, rf * 1.12, rf * 1.12, "collar", base=base)


def arm_canvas(st, side, frame, body_mask=None, torso_mask=None):
    c = StyleCanvas(st)
    shoulder, elbow, (hx, hy), prop = arm_pose(st, side, frame)
    ru, rf = st["arm_r"]
    base = 0.95 if side == "l" else 0.75
    sleeve = st["sleeve"]
    pw, ph = st["phone"]
    if prop == "phone_up":
        x0, y0 = int(hx - pw), int(hy - ph - 1)
        c.rect(x0, y0, x0 + pw, y0 + ph, "phone", 0.6)
    if prop == "phone_low":
        x0, y0 = int(hx - pw / 2), int(hy)
        c.rect(x0, y0, x0 + pw, y0 + ph, "phone", 0.4)
    fl = math.hypot(hx - elbow[0], hy - elbow[1]) or 1.0
    ux, uy = (hx - elbow[0]) / fl, (hy - elbow[1]) / fl
    wrist = (hx - ux * st["hand_r"] * 1.1, hy - uy * st["hand_r"] * 1.1)
    c.capsule(shoulder, elbow, ru, (ru + rf) / 2, sleeve, base=base)
    c.capsule(elbow, wrist, (ru + rf) / 2, rf, sleeve, base=base * 1.05)
    if st["char"]["outfit"]["top"].get("cuffs"):
        _sleeve_cuff(c, st, elbow, wrist, base)
    if prop == "wrap":
        wrap(c, st, hx, hy, WRAP_ANGLE[frame])
    if prop == "bag":
        bag(c, st, hx, hy, BAG_SWING[frame])
    if prop in ("vial", "vial_back"):
        vial(c, st, hx, hy, VIAL_ANGLE[prop])
    if prop == "knife":
        knife(c, st, hx, hy, KNIFE_ANGLE[frame])
    if prop != "behind":
        c.ellipse(hx, hy, st["hand_r"], st["hand_r"] * 1.05, "skin", base=1.0)
    if prop == "bag":
        # handle wrapped over the knuckles
        for x in range(int(hx - st["hand_r"]), int(hx + st["hand_r"]) + 1):
            if c.mat[int(hy)][x] == "skin":
                c.shade_px(x, int(hy), "bag", 0.7)
    if prop == "ball":
        k = st["prop_k"]
        c.ellipse(hx + 0.5 * k, hy - 2.0 * k, max(1.2, 2.2 * k), max(1.1, 2.0 * k), "paper", base=1.1)
    if side == "r" and frame in FAR_TUCKED and torso_mask is not None:
        for y in range(c.h):
            for x in range(c.w):
                if torso_mask[y][x] and c.mat[y][x] == st["sleeve"]:
                    c.clear(x, y)
    if prop == "behind" and body_mask is not None:
        cut = (elbow[1] + hy) / 2
        for y in range(c.h):
            for x in range(c.w):
                if y >= cut and body_mask[y][x]:
                    c.clear(x, y)
    return c


# ── assembly ────────────────────────────────────────────────────────
def arm_frames(char, table):
    """Frames of a pose table this character gets (props it doesn't carry are dropped)."""
    props = set(char.get("props", []))
    return [f for f, (_, _, p) in table.items() if p is None or PROP_GROUP[p] in props]


def anchors(st):
    s = st["scale"]
    k = st["prop_k"]

    def full(p):
        return [round(p[0] * s, 1), round(p[1] * s, 1)]

    char = st["char"]
    hands = {"l": {}, "r": {}}
    for side, table in (("l", POSE_L), ("r", POSE_R)):
        for f in arm_frames(char, table):
            _, _, (hx, hy), prop = arm_pose(st, side, f)
            if prop == "ball":
                hy -= 2.0 * k
            if prop in ("vial", "vial_back"):
                a = math.radians(VIAL_ANGLE[prop])
                ln = max(st.get("vial_min", 4.0), 8.0 * k) * 0.5
                hx, hy = hx + math.cos(a) * ln, hy + math.sin(a) * ln
            hands[side][f] = full((hx, hy))
    mx, my = st["mouth"]
    nx, ny = st["neck"]
    return {"mouth": full((mx + st["fdx"], my + st["dy_head"])), "neck": full((nx, ny + st["dy_head"])),
            "hand_l": hands["l"], "hand_r": hands["r"]}


def build(style, char):
    st = spec(style, char)
    torso_c = torso_canvas(st)
    legs_c = legs_canvas(st)
    torso_mask = torso_c.mask()
    body_mask = [[torso_mask[y][x] or legs_c.mat[y][x] is not None for x in range(torso_c.w)] for y in range(torso_c.h)]
    images = {"shadow.png": shadow(st), "legs.png": legs_c.finish(), "torso.png": torso_c.finish(), "head.png": head(st)}
    for i, pose in enumerate(WALK):
        images["legs_walk_%d.png" % i] = legs_canvas(st, pose).finish()
    for f in EYE_FRAMES:
        images["eyes_%s.png" % f] = overlay_eyes(st, f)
    for f in BROW_FRAMES:
        images["brows_%s.png" % f] = overlay_brows(st, f)
    for f in MOUTH_FRAMES:
        images["mouth_%s.png" % f] = overlay_mouth(st, f)
    if char.get("glasses"):
        images["glasses.png"] = overlay_glasses(st)
    for side, table in (("l", POSE_L), ("r", POSE_R)):
        for f in arm_frames(char, table):
            images["arm_%s_%s.png" % (side, f)] = arm_canvas(st, side, f, body_mask, torso_mask).finish()
    return images


def manifest(base, style, char, rig_id):
    """Rig manifest for a kit character: base is build_stage_assets.rig_manifest(); parts,
    anchors, actions and the walk cycle come from the kit."""
    st = spec(style, char)
    m = dict(base)
    m["id"] = rig_id
    m["dir"] = "res://assets/stages/rigs/%s/" % rig_id
    m["anchors"] = anchors(st)
    frames = lambda prefix, names: {n: "%s_%s.png" % (prefix, n) for n in names}
    parts = dict(base["parts"])
    legs = {"base": "legs.png"}
    legs.update({"walk_%d" % i: "legs_walk_%d.png" % i for i in range(len(WALK))})
    parts["legs"] = {"group": "root", "frames": legs}
    parts["eyes"] = {"group": "head", "frames": frames("eyes", EYE_FRAMES)}
    parts["brows"] = {"group": "head", "frames": frames("brows", BROW_FRAMES)}
    parts["mouth"] = {"group": "head", "frames": frames("mouth", MOUTH_FRAMES)}
    parts["arm_l"] = {"group": "body", "frames": frames("arm_l", arm_frames(char, POSE_L))}
    parts["arm_r"] = {"group": "body", "frames": frames("arm_r", arm_frames(char, POSE_R))}
    order = list(base["order"])
    if char.get("glasses"):
        parts["glasses"] = {"group": "head", "frames": {"base": "glasses.png"}}
        order.insert(order.index("brows") + 1, "glasses")
    m["parts"] = parts
    m["order"] = order
    actions = dict(base["actions"])
    actions.update(ACTIONS)
    m["actions"] = {name: steps for name, steps in actions.items()
                    if all(v in parts[p]["frames"] for s in steps for p, v in s["set"].items())}
    m["walk"] = {"part": "legs", "frames": ["walk_%d" % i for i in range(len(WALK))],
                 "frame_time": WALK_FRAME_TIME, "stand": "base"}
    defaults = dict(base["defaults"])
    for part in ("arm_l", "arm_r"):
        if defaults[part] not in parts[part]["frames"]:
            defaults[part] = "rest"
    m["defaults"] = defaults
    return m
