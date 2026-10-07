"""Archie in three alternative pixel-art styles (style mock-ups).

Same frame names, canvas (96x168) and origin (48,159) as rig_archie.py, so any
of these drops into the engine as a rig. Styles:

  chibi      SNES/Stardew-style RPG: ~2.5 heads tall, big eyes, flat 3-tone
             cel shading, uniform dark outline.
  adventure  Point-and-click adventure (LucasArts/Wadjet Eye): lanky, small
             head, hue-shifted 4-tone ramps, coloured sel-out outline, no dither.
  retro      NES/PICO-8-style: drawn at half resolution then doubled, 2 tones
             per material, hard black outline.

Arms are posed by 2-bone IK from a shared pose table, scaled to each style's
arm length, so the same rig actions work for every style.
"""
import math

from PIL import Image

from raster import Canvas, Material, darken

W, H = 96, 168
ORIGIN = (48, 159)

# Hand targets relative to the shoulder, in units of rig_archie's arm (length 38),
# plus an elbow hint (which side the elbow bends to). Viewer-left arm (arm_l);
# arm_r entries are written for the viewer-right arm directly.
POSE_L = {
    "rest": ((2, 37), (-4, 18), None),
    "hold": ((6, 24), (-5, 18), "wrap"),
    "eat": (None, (-4, 18), "wrap"),
    "wave_a": ((-13, -12), (-12, 6), "wrap"),
    "wave_b": ((-18, -10), (-12, 6), "wrap"),
    "crumple": ((6, 22), (-5, 18), "ball"),
    "throw_back": ((-5, -14), (-12, 2), "ball"),
    "throw_release": ((-24, -6), (-12, 6), None),
}
WRAP_ANGLE = {"hold": -60, "eat": -55, "wave_a": -95, "wave_b": -120}
POSE_R = {
    "rest": ((-2, 37), (4, 18), None),
    "phone_up": ((-8, 10), (4, 18), "phone_up"),
    "phone_low": ((2, 33), (5, 18), "phone_low"),
}
BROW_FRAMES = ["normal", "up", "knit", "quirk"]


def M(ramp, outline):
    return Material(ramp, outline=outline)


# ── style definitions ───────────────────────────────────────────────
INK = "#22151b"
CHIBI = dict(
    name="chibi", scale=1, outline="ink",
    mats={
        "skin": M(["#a8653f", "#d69560", "#f2bd8b"], INK),
        "hair": M(["#2e180e", "#4d2d18", "#704427"], INK),
        "beard": M(["#4a2c1a", "#5e3a22", "#5e3a22"], INK),
        "jacket": M(["#3b4826", "#56683a", "#748a4b"], INK),
        "collar": M(["#4a5a30", "#6a7f45", "#86995a"], INK),
        "tee": M(["#aaa49b", "#d4cfc6", "#efebe3"], INK),
        "jeans": M(["#1a1c28", "#262a3c", "#353b54"], INK),
        "shoe": M(["#bcb8b0", "#e8e4dc", "#fefcf8"], INK),
        "sole": M(["#a29d93", "#c9c4ba"], INK),
        "paper": M(["#cfc7b7", "#f1ebdf"], INK),
        "food": M(["#7d4620", "#ab6a30", "#cf8f48"], INK),
        "phone": M(["#17181f", "#2b2e3a"], INK),
    },
    face=(48, 86, 12.5, 12.5), neck=(48, 99), mouth=(48, 94), face_tones=(0.8, 0.5),
    hair=dict(cap=(48, 77, 14.5, 9.5), curl_r=4.2, ring=(13.5, 10.0), n=8, inner=4, fringe_y=78),
    ears=(1.8, 2.6), ear_y=88,
    torso=dict(top=98, sh_y=102, sw=12, hem=129, hw=11, neck_w=3),
    legs=dict(hip=125, foot=158, leg_w=8, gap=1, shoe_h=5, toe=2),
    shoulders=((37, 104), (59, 104)), arm=(10.5, 10.5), arm_r=(3.8, 3.4), hand_r=2.5,
    eat_hand=(-6, 6), prop_k=0.75, phone=(4, 7), shadow=(18, 2.6),
    beard=dict(y=92, side_y=86, mouth=(44, 51, 92, 95)), nose="chibi",
    eyes={
        "key": {"L": INK, "P": "#1f120c", "h": "#fffaf0", "W": "#f4ece0"},
        "open": ((42, 85), ["hP", "PP", "PP", "PP"], (52, 85), ["hP", "PP", "PP", "PP"]),
        "down": ((42, 87), ["LL", "PP", "PP"], (52, 87), ["LL", "PP", "PP"]),
        "closed": ((42, 88), ["LL"], (52, 88), ["LL"]),
        "wide": ((41, 84), [".W.", "WhP", "WPP", "WPP", ".W."], (52, 84), [".W.", "hPW", "PPW", "PPW", ".W."]),
    },
    brows={
        "key": {"B": "#24140b"},
        "normal": (82, [".BB", "B.."]),
        "up": (80, [".BB", "B.."]),
        "knit": (82, ["BB.", "..B"]),
        "x": (41, 52),
    },
    mouths={
        "key": {"D": "#26100e", "T": "#f0e8dc", "l": "#b06a4c", "F": "#ab6a30"},
        "x": 46,
        "closed": (93, ["D..D", ".DD."]),
        "chew_a": (94, [".DD."]),
        "chew_b": (93, [".DD.", "DDDD"]),
        "talk_a": (93, [".DD.", ".DD."]),
        "talk_b": (93, ["DTTD", "DDDD", ".DD."]),
        "agape": (92, [".DD.", "DTTD", "DDDD", "DFDD", ".DD."]),
        "smirk": (93, ["...D", "DDD."]),
    },
)

ADVENTURE = dict(
    name="adventure", scale=1, outline="selout",
    mats={
        "skin": M(["#6e3b3a", "#9c5b47", "#c7865c", "#e8b183"], None),
        "hair": M(["#1d1021", "#36211f", "#513327", "#6f4934"], None),
        "beard": M(["#26151f", "#3e2822", "#553a2b", "#553a2b"], None),
        "jacket": M(["#1d2a29", "#33422f", "#4c5c35", "#6c7d45"], None),
        "collar": M(["#2a3a32", "#45573a", "#62743f", "#83955a"], None),
        "tee": M(["#6c6a7a", "#9c98a3", "#c7c2bf", "#e9e3d6"], None),
        "jeans": M(["#101120", "#1a1c2e", "#262a44", "#353a5c"], None),
        "shoe": M(["#878599", "#b7b4bf", "#dedad7", "#fbf7ec"], None),
        "sole": M(["#6c6a7a", "#9c98a3", "#c7c2bf"], None),
        "paper": M(["#9c94a0", "#cfc6c0", "#f1eadc"], None),
        "food": M(["#5e2f22", "#8a4b26", "#b4722f", "#d39a4d"], None),
        "phone": M(["#0f1020", "#1d2034", "#2f3450"], None),
    },
    face=(48, 52, 7.5, 9.5), neck=(48, 62), mouth=(48, 58), face_tones=(0.62, 0.4),
    hair=dict(cap=(48, 44.5, 8.6, 6.0), curl_r=2.8, ring=(8.0, 6.6), n=9, inner=3, fringe_y=45),
    ears=(1.2, 2.2), ear_y=53,
    torso=dict(top=61, sh_y=66, sw=14, hem=105, hw=12, neck_w=3),
    legs=dict(hip=100, foot=158, leg_w=7, gap=1, shoe_h=5, toe=4),
    shoulders=((36, 69), (60, 69)), arm=(17.5, 17.0), arm_r=(3.6, 3.2), hand_r=2.6,
    eat_hand=(-10, 11), prop_k=0.9, phone=(5, 9), shadow=(22, 3.0),
    beard=dict(y=56, side_y=51, mouth=(45, 50, 56, 58)), nose="adventure",
    eyes={
        "key": {"L": "#2a161a", "P": "#1a0e10", "W": "#e9e3d6", "s": "#9c5b47"},
        "open": ((44, 51), ["LL", "WP"], (50, 51), ["LL", "PW"]),
        "down": ((44, 51), ["ss", "LL"], (50, 51), ["ss", "LL"]),
        "closed": ((44, 52), ["LL"], (50, 52), ["LL"]),
        "wide": ((44, 50), ["WW", "WP", "WW"], (50, 50), ["WW", "PW", "WW"]),
    },
    brows={
        "key": {"B": "#22121a"},
        "normal": (49, ["BB"]),
        "up": (48, [".B", "B."]),
        "knit": (48, ["B.", ".B"]),
        "x": (44, 50),
    },
    mouths={
        "key": {"D": "#2e1416", "T": "#e9e3d6", "l": "#9c5b47", "F": "#b4722f"},
        "x": 46,
        "closed": (57, ["DDDD"]),
        "chew_a": (57, [".DD."]),
        "chew_b": (57, [".DD.", ".ll."]),
        "talk_a": (57, [".DD.", ".DD."]),
        "talk_b": (57, ["DTTD", ".DD."]),
        "agape": (57, ["DTTD", "DDDD", "DFDD", ".DD."]),
        "smirk": (57, ["...D", "DDD."]),
    },
)

BLACK = "#000000"
RETRO = dict(
    name="retro", scale=2, outline="ink",
    mats={
        "skin": M(["#a65a3a", "#e39d6b"], BLACK),
        "hair": M(["#2a1408", "#5e3218"], BLACK),
        "beard": M(["#3c1e0e", "#3c1e0e"], BLACK),
        "jacket": M(["#2c4a1e", "#5c7c2c"], BLACK),
        "collar": M(["#5c7c2c", "#7c9c3c"], BLACK),
        "tee": M(["#9e9a92", "#ece8dc"], BLACK),
        "jeans": M(["#181c34", "#2c3456"], BLACK),
        "shoe": M(["#a8a8b4", "#fcfcfc"], BLACK),
        "sole": M(["#7a7a86", "#a8a8b4"], BLACK),
        "paper": M(["#c8c0a8", "#fcf8e8"], BLACK),
        "food": M(["#8a4a18", "#c8782a"], BLACK),
        "phone": M(["#101018", "#303848"], BLACK),
    },
    face=(24, 30, 5.8, 6.2), neck=(24, 37), mouth=(24, 34), face_tones=(0.8, 0.3),
    hair=dict(cap=(24, 25.5, 6.8, 4.2), curl_r=1.9, ring=(6.2, 4.6), n=7, inner=2, fringe_y=26),
    ears=(0.9, 1.4), ear_y=31,
    torso=dict(top=36, sh_y=39, sw=7, hem=57, hw=6, neck_w=2),
    legs=dict(hip=55, foot=78, leg_w=4, gap=0, shoe_h=3, toe=1),
    shoulders=((17.5, 40.5), (30.5, 40.5)), arm=(8.0, 8.0), arm_r=(2.1, 1.9), hand_r=1.4,
    eat_hand=(-3.5, 3.5), prop_k=0.42, phone=(2, 4), shadow=(10, 1.4),
    beard=dict(y=34, side_y=30, mouth=(21, 26, 33, 35)), nose="retro",
    eyes={
        "key": {"P": "#140a06", "W": "#fcfcfc", "s": "#a65a3a"},
        "open": ((21, 30), ["P", "P"], (26, 30), ["P", "P"]),
        "down": ((21, 31), ["P"], (26, 31), ["P"]),
        "closed": ((21, 31), ["s"], (26, 31), ["s"]),
        "wide": ((20, 29), ["WP", "WP"], (26, 29), ["PW", "PW"]),
    },
    brows={
        "key": {"B": "#1c0e06"},
        "normal": (28, ["BB"]),
        "up": (27, ["BB"]),
        "knit": (28, ["B.", ".B"]),
        "x": (20, 26),
    },
    mouths={
        "key": {"D": "#2a0e08", "T": "#fcfcfc", "F": "#c8782a"},
        "x": 22,
        "closed": (34, [".DD."]),
        "chew_a": (34, ["..DD"]),
        "chew_b": (34, ["DD.."]),
        "talk_a": (34, [".DD.", ".DD."]),
        "talk_b": (34, ["DDDD", ".DD."]),
        "agape": (33, [".DD.", "DTTD", "DFDD", ".DD."]),
        "smirk": (34, ["...D", "DDD."]),
    },
)

STYLES = {"chibi": CHIBI, "adventure": ADVENTURE, "retro": RETRO}


# ── canvas with style-aware outline ─────────────────────────────────
class StyleCanvas(Canvas):
    def __init__(self, style):
        s = style["scale"]
        super().__init__(W // s, H // s, style["mats"])
        self.style = style

    def finish(self, outline=True):
        if outline and self.style["outline"] == "selout":
            img = self._render_selout()
        else:
            img = self.render(outline=outline)
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
                        ramp = self.materials[m].ramp
                        lit = ddx == 1 or ddy == 1
                        c = ramp[0] if lit else darken(ramp[0], 0.62)
                    if best is None or sum(c[:3]) < sum(best[:3]):
                        best = c
                if best is not None:
                    out[x, y] = best
        return img


def _in_ell(x, y, e):
    cx, cy, rx, ry = e
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


# ── legs + shadow ───────────────────────────────────────────────────
def legs(st):
    c = StyleCanvas(st)
    g = st["legs"]
    cx = c.w // 2
    hip, foot, lw, gap, sh, toe = g["hip"], g["foot"], g["leg_w"], g["gap"], g["shoe_h"], g["toe"]
    ankle = foot - sh
    half = gap / 2.0
    left = [(cx - half - lw - 0.5, hip), (cx - half, hip), (cx - half, ankle + 1), (cx - half - lw + 0.5, ankle + 1)]
    right = [(cx + half, hip), (cx + half + lw + 0.5, hip), (cx + half + lw - 0.5, ankle + 1), (cx + half, ankle + 1)]
    c.poly(left, "jeans", base=0.9, peak=0.3)
    c.poly(right, "jeans", base=0.75, peak=0.35)
    # shoes: toes turn slightly outward
    lx0, lx1 = cx - half - lw, cx - half
    rx0, rx1 = cx + half, cx + half + lw
    c.poly([(lx0 + 0.5, ankle), (lx1, ankle), (lx1, foot), (lx0 - toe, foot), (lx0 - toe, foot - 1.5)], "shoe", base=1.0, peak=0.35)
    c.poly([(rx0, ankle), (rx1 - 0.5, ankle), (rx1 + toe, foot - 1.5), (rx1 + toe, foot), (rx0, foot)], "shoe", base=0.9, peak=0.4)
    for x in range(int(lx0 - toe), int(lx1)):
        c.shade_px(x, foot - 1, "sole", 0.6)
    for x in range(int(rx0), int(rx1 + toe)):
        c.shade_px(x, foot - 1, "sole", 0.6)
    return c.finish()


def shadow(st):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    p = img.load()
    cx, cy = ORIGIN
    rx, ry = st["shadow"]
    rx, ry = rx * 1.0, ry * 1.0
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if d <= 1.0 and 0 <= y < H:
                p[x, y] = (12, 8, 10, 110 if d < 0.55 else 60)
    return img


# ── torso ───────────────────────────────────────────────────────────
def torso(st):
    c = StyleCanvas(st)
    t = st["torso"]
    cx = c.w / 2.0
    top, shy, sw, hem, hw, nw = t["top"], t["sh_y"], t["sw"], t["hem"], t["hw"], t["neck_w"]
    body = [(cx - nw - 1, top + 1), (cx - sw + 2, shy - 1), (cx - sw, shy + 2), (cx - hw, hem), (cx + hw, hem),
            (cx + sw, shy + 2), (cx + sw - 2, shy - 1), (cx + nw + 1, top + 1)]
    c.poly(body, "jacket", base=0.85, peak=0.3)
    c.rect(int(cx - nw), int(top - 3), int(cx + nw - 1), int(top + 1), "skin", 0.3)
    # tee between the open fronts
    tw = max(2, round(sw * 0.26))
    tee = [(cx - tw + 0.5, top + 1), (cx + tw - 0.5, top + 1), (cx + tw, hem), (cx - tw, hem)]
    c.poly(tee, "tee", base=1.0, peak=0.4)
    # collar points
    cl = max(2, round(sw * 0.35))
    c.poly([(cx - tw, top), (cx - tw + 1, top + cl + 1), (cx - tw - cl, top + cl - 1), (cx - nw - 1, top)], "collar", base=1.0, cyl=False)
    c.poly([(cx + tw, top), (cx + tw - 1, top + cl + 1), (cx + tw + cl, top + cl - 1), (cx + nw + 1, top)], "collar", base=0.55, cyl=False)
    # placket buttons on viewer-left front, pocket on viewer-right
    bx = int(cx - tw - 1)
    step = max(3, (hem - top) // 5)
    for y in range(int(top + cl + 3), int(hem - 2), step):
        c.shade_px(bx, y, "jacket", 0.0)
    px0, px1 = int(cx + tw + 2), int(cx + sw - 2)
    py0 = int(shy + 3)
    ph = max(3, round((hem - top) * 0.22))
    if px1 - px0 >= 3:
        for x in range(px0, px1 + 1):
            c.shade_px(x, py0, "jacket", 0.0)
            c.shade_px(x, py0 + ph, "jacket", 0.0)
        for y in range(py0, py0 + ph + 1):
            c.shade_px(px0, y, "jacket", 0.0)
            c.shade_px(px1, y, "jacket", 0.0)
    return c.finish()


# ── head ────────────────────────────────────────────────────────────
def hair_curls(st):
    h = st["hair"]
    hx, hy, _, _ = h["cap"]
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


def head(st):
    c = StyleCanvas(st)
    face = st["face"]
    fx, fy, frx, fry = face
    erx, ery = st["ears"]
    c.ellipse(fx - frx + 0.2, st["ear_y"], erx, ery, "skin", base=0.7)
    c.ellipse(fx + frx - 0.2, st["ear_y"], erx, ery, "skin", base=0.45)
    hx, hy, hrx, hry = st["hair"]["cap"]
    c.ellipse(hx, hy, hrx, hry, "hair", base=0.6)
    lit, shade = st["face_tones"]
    c.ellipse(fx, fy, frx, fry, "skin", base=lit, flat=True)
    for y in range(c.h):
        for x in range(c.w):
            if _in_ell(x, y, face) and x + 0.5 > fx + frx * 0.55:
                c.shade_px(x, y, "skin", shade)
    # beard: lower face and sideburns, leaving a skin patch for the mouth
    b = st["beard"]
    mx0, mx1, my0, my1 = b["mouth"]
    for y in range(c.h):
        for x in range(c.w):
            if not _in_ell(x, y, face):
                continue
            side = abs(x + 0.5 - fx) >= frx - (1.6 if st["scale"] == 2 else 2.5)
            if (y >= b["y"] or (side and y >= b["side_y"])) and not (mx0 <= x <= mx1 and my0 <= y <= my1):
                c.shade_px(x, y, "beard", 0.9 - 0.25 * (x + 0.5 > fx))
    # chin line of beard sits one row under the jaw
    for x in range(int(fx - frx * 0.55), int(fx + frx * 0.55) + 1):
        c.shade_px(x, int(fy + fry), "beard", 0.4)
    nose(c, st)
    curls = hair_curls(st)
    for (cx, cy, r) in curls:
        c.ellipse(cx, cy, r, r * 0.92, "hair", base=1.1)
    # curl texture: a dark hook under each curl, a lit tuft on top
    for (cx, cy, r) in curls:
        for deg in range(10, 150, 12):
            a = math.radians(deg)
            x, y = int(cx + r * 0.7 * math.cos(a)), int(cy + r * 0.62 * math.sin(a))
            if c.mat[y][x] == "hair":
                c.shade_px(x, y, "hair", 0.05)
        x, y = int(cx - r * 0.3), int(cy - r * 0.45)
        if c.mat[y][x] == "hair":
            c.shade_px(x, y, "hair", 1.0)
    for _ in range(2):
        holes = [(x, y) for y in range(1, c.h - 1) for x in range(1, c.w - 1)
                 if c.mat[y][x] is None and sum(c.mat[y + dy][x + dx] is not None for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))) >= 3]
        for (x, y) in holes:
            c.shade_px(x, y, "hair", 0.45)
    # hairline: forehead clear below the fringe
    fringe = st["hair"]["fringe_y"]
    for y in range(int(fringe), int(fy)):
        for x in range(c.w):
            if _in_ell(x, y, face) and c.mat[y][x] == "hair" and abs(x + 0.5 - fx) < frx - 1.2:
                if not (y == int(fringe) and (x % 3 == 0)):
                    c.shade_px(x, y, "skin", lit if x + 0.5 <= fx + frx * 0.55 else shade)
    return c.finish()


def nose(c, st):
    fx, fy, _, _ = st["face"]
    x = int(fx)
    kind = st["nose"]
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
    return c.finish(outline=False)


def overlay_brows(st, frame):
    c = StyleCanvas(st)
    b = st["brows"]
    lx, rx = b["x"]
    yl, rl = b["normal" if frame == "quirk" else frame]
    yr, rr = b["up" if frame == "quirk" else frame]
    c.stamp(lx, yl, rl, b["key"])
    c.stamp(rx, yr, [row[::-1] for row in rr], b["key"])
    return c.finish(outline=False)


def overlay_mouth(st, frame):
    c = StyleCanvas(st)
    m = st["mouths"]
    y, rows = m[frame]
    c.stamp(m["x"], y, rows, m["key"])
    return c.finish(outline=False)


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
    a, b = st["arm"]
    k = (a + b) / 38.0
    rel, hint, prop = (POSE_L if side == "l" else POSE_R)[frame]
    if rel is None:
        mx, my = st["mouth"]
        target = (mx + st["eat_hand"][0], my + st["eat_hand"][1])
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


def arm(st, side, frame):
    c = StyleCanvas(st)
    shoulder, elbow, (hx, hy), prop = arm_pose(st, side, frame)
    ru, rf = st["arm_r"]
    base = 0.95 if side == "l" else 0.75
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
    c.capsule(shoulder, elbow, ru, (ru + rf) / 2, "jacket", base=base)
    c.capsule(elbow, wrist, (ru + rf) / 2, rf, "jacket", base=base * 1.05)
    if prop == "wrap":
        wrap(c, st, hx, hy, WRAP_ANGLE[frame])
    c.ellipse(hx, hy, st["hand_r"], st["hand_r"] * 1.05, "skin", base=1.0)
    if prop == "ball":
        k = st["prop_k"]
        c.ellipse(hx + 0.5 * k, hy - 2.0 * k, max(1.2, 2.2 * k), max(1.1, 2.0 * k), "paper", base=1.1)
    return c.finish()


# ── assembly ────────────────────────────────────────────────────────
def anchors(st):
    s = st["scale"]

    def full(p, dy=0.0):
        return [round(p[0] * s, 1), round((p[1] + dy) * s, 1)]

    hands_l, hands_r = {}, {}
    for f in POSE_L:
        _, _, hand, prop = arm_pose(st, "l", f)
        hands_l[f] = full(hand, -2.0 * st["prop_k"] if prop == "ball" else 0.0)
    for f in POSE_R:
        hands_r[f] = full(arm_pose(st, "r", f)[2])
    return {"mouth": full(st["mouth"]), "neck": full(st["neck"]), "hand_l": hands_l, "hand_r": hands_r}


def build(st):
    images = {"shadow.png": shadow(st), "legs.png": legs(st), "torso.png": torso(st), "head.png": head(st)}
    for f in ["open", "down", "closed", "wide"]:
        images["eyes_%s.png" % f] = overlay_eyes(st, f)
    for f in BROW_FRAMES:
        images["brows_%s.png" % f] = overlay_brows(st, f)
    for f in ["closed", "chew_a", "chew_b", "talk_a", "talk_b", "agape", "smirk"]:
        images["mouth_%s.png" % f] = overlay_mouth(st, f)
    for f in POSE_L:
        images["arm_l_%s.png" % f] = arm(st, "l", f)
    for f in POSE_R:
        images["arm_r_%s.png" % f] = arm(st, "r", f)
    return images
