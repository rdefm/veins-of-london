"""Archie stage rig: layered parts on a shared 96x168 canvas, feet at ORIGIN.

Likeness source: assets/character-references/Archie/Archie_reference.png
(curly dark-brown hair, short beard, olive overshirt with a chest pocket,
pale grey tee, black jeans, white trainers).
"""
import math

from raster import Canvas, Material, hexc

W, H = 96, 168
ORIGIN = (48, 159)
NECK = (48, 34)
MOUTH = (48, 30)
SHOULDER_L = (30, 42)
SHOULDER_R = (66, 42)

MATS = {
    "skin": Material(["#6e4029", "#8d5a3b", "#ab754f", "#c48e66", "#d9a87f"], outline="#43251a"),
    "hair": Material(["#130a05", "#20130b", "#2e1c11", "#412818", "#583723"], outline="#0d0603", dither=0.22),
    "beard": Material(["#26170e", "#382416", "#4e3321", "#684631"], outline="#1a0f08", dither=0.35),
    "jacket": Material(["#1a2013", "#252e1b", "#323d24", "#414d2e", "#525f39"], outline="#10140b", dither=0.16, edge_against=("tee", "skin")),
    "collar": Material(["#252e1b", "#323d24", "#414d2e", "#566442"], outline="#10140b"),
    "tee": Material(["#7a736c", "#958e86", "#b1aaa1", "#c8c1b8", "#d9d4cb"], outline="#4c4741"),
    "jeans": Material(["#0e0f13", "#15161c", "#1d1f27", "#272a33", "#33363f"], outline="#060709", dither=0.2),
    "shoe": Material(["#8c8882", "#b2aea7", "#d0ccc5", "#e7e4de", "#f6f4ef"], outline="#504d48"),
    "sole": Material(["#b9b3a8", "#d3cec4", "#e2ddd4"], outline="#57534d"),
    "paper": Material(["#a39c91", "#cbc4b8", "#e7e1d6", "#f7f3eb"], outline="#666057"),
    "food": Material(["#4f2b12", "#73441f", "#98622e", "#b47c3e"], outline="#331b09"),
    "phone": Material(["#121318", "#1c1e25", "#292c35", "#3a3e4a"], outline="#060608"),
}

SKIN_SHADOW = "#8d5a3b"
LASH = "#170d08"
WHITE = "#e4dace"
IRIS = "#4a2c1a"
PUPIL = "#120904"
BROW = "#1e120b"
BROW_SOFT = "#3a2617"
MOUTH_DARK = "#2a1410"
LIP = "#94573f"
TEETH = "#e6ddd0"
BEARD_PX = "#2e1e14"
FOOD_PX = "#98622e"
GREEN_PX = "#5d7a2c"


def mirror_rows(rows):
    return [r[::-1] for r in rows]


def new():
    return Canvas(W, H, MATS)


# ── legs ────────────────────────────────────────────────────────────
def legs():
    c = new()
    left = [(31, 70), (48, 70), (48, 88), (47, 104), (46, 118), (46, 147), (34, 147), (33, 118), (32, 104), (31, 88)]
    right = [(48, 70), (65, 70), (65, 88), (64, 104), (63, 118), (62, 147), (50, 147), (50, 118), (49, 104), (49, 88)]
    c.poly(left, "jeans", base=0.85, peak=0.3)
    c.poly(right, "jeans", base=0.78, peak=0.35)
    # crotch gap
    for y in range(90, 148):
        c.clear(48, y)
    # knee and ankle stacking creases
    for (x0, x1, y) in [(35, 44, 119), (51, 61, 119), (35, 45, 139), (51, 61, 140), (35, 45, 143), (51, 61, 144)]:
        for x in range(x0, x1 + 1):
            if (x + y) % 3 != 0:
                c.shade_px(x, y, "jeans", 0.05)
    # shoes: toes turn slightly outward
    ls = [(34, 146), (46, 146), (47, 152), (46, 158), (29, 158), (29, 155), (32, 151)]
    rs = [(50, 146), (62, 146), (64, 151), (67, 155), (67, 158), (50, 158), (49, 152)]
    c.poly(ls, "shoe", base=0.95, peak=0.35)
    c.poly(rs, "shoe", base=0.9, peak=0.4)
    for x in range(29, 47):
        c.shade_px(x, 157, "sole", 0.6)
        c.shade_px(x, 158, "sole", 0.3)
    for x in range(50, 68):
        c.shade_px(x, 157, "sole", 0.6)
        c.shade_px(x, 158, "sole", 0.3)
    for (x, y) in [(38, 148), (40, 148), (42, 148), (39, 150), (41, 150), (54, 148), (56, 148), (58, 148), (55, 150), (57, 150)]:
        c.shade_px(x, y, "shoe", 0.25)
    for (x, y) in [(31, 155), (32, 154), (33, 154), (63, 154), (64, 155)]:
        c.shade_px(x, y, "shoe", 1.0)
    return c.render()


def shadow():
    from PIL import Image
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    p = img.load()
    cx, cy, rx, ry = 48, 159, 25, 3.2
    for y in range(int(cy - 4), int(cy + 5)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if d <= 1.0:
                p[x, y] = (12, 8, 10, 110 if d < 0.55 else 60)
    return img


# ── torso ───────────────────────────────────────────────────────────
def torso():
    c = new()
    body = [(41, 35), (33, 37), (26, 40), (24, 46), (28, 50), (29, 64), (30, 76), (31, 80), (65, 80), (66, 76),
            (67, 64), (68, 50), (72, 46), (70, 40), (63, 37), (55, 35)]
    c.poly(body, "jacket", base=0.8, peak=0.32)
    # neck
    c.rect(44, 31, 51, 39, "skin", 0.32)
    for y in range(31, 40):
        c.shade_px(51, y, "skin", 0.15)
    # tee visible between the open fronts
    tee = [(43, 38), (47, 40.5), (49, 40.5), (53, 38), (55, 44), (56, 80), (40, 80), (41, 44)]
    c.poly(tee, "tee", base=0.95, peak=0.38)
    for x in range(43, 54):
        y = 38 if x in (43, 52, 53) else (39 if x in (44, 45, 50, 51) else 40)
        c.shade_px(x, y, "tee", 0.3)
    # tee shadow under the jacket fronts
    for y in range(44, 80):
        c.shade_px(41 if y < 60 else 40, y, "tee", 0.2)
        c.shade_px(55 if y < 60 else 56, y, "tee", 0.35)
    # collar points
    lc = [(43, 33), (45, 38), (43, 44), (36, 39), (39, 35)]
    c.poly(lc, "collar", base=0.95, peak=0.6)
    c.poly([(95 - x + 1, y) for (x, y) in lc], "collar", base=0.8, peak=0.4)
    # front placket buttons (Archie's right front, viewer left)
    for y in (48, 56, 64, 72):
        c.px(38, y, "#10140b")
        c.px(38, y - 1, "#566442")
    # chest pocket on viewer-right front
    for x in range(57, 65):
        c.shade_px(x, 50, "jacket", 0.95)
        c.shade_px(x, 53, "jacket", 0.0)
        c.shade_px(x, 60, "jacket", 0.05)
    for y in range(50, 61):
        c.shade_px(57, y, "jacket", 0.05)
        c.shade_px(64, y, "jacket", 0.0)
    for x in range(58, 64):
        c.shade_px(x, 51, "jacket", 0.75)
        c.shade_px(x, 52, "jacket", 0.6)
    c.px(60, 52, "#10140b")
    # hem band and fold hints
    for x in range(31, 66):
        if x < 40 or x > 56:
            c.shade_px(x, 77, "jacket", 0.1)
    for (x, y0, y1) in [(33, 52, 70), (63, 64, 74), (37, 44, 58)]:
        for y in range(y0, y1):
            c.shade_px(x, y, "jacket", 0.12)
    for (x, y0, y1) in [(35, 50, 66)]:
        for y in range(y0, y1, 2):
            c.shade_px(x, y, "jacket", 0.95)
    return c.render()


# ── head ────────────────────────────────────────────────────────────
FACE = (48, 24.5, 8.2, 10.0)


def in_face(x, y):
    cx, cy, rx, ry = FACE
    return ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0


def beard_top(x):
    adx = abs(x + 0.5 - 48)
    if adx >= 7:
        return 25
    if adx >= 5:
        return 27
    return 27


def head():
    c = new()
    # ears behind the face
    c.ellipse(39.9, 23.5, 1.3, 2.2, "skin", base=0.55)
    c.ellipse(56.1, 23.5, 1.3, 2.2, "skin", base=0.4)
    # back-of-hair mass behind the face sides
    c.ellipse(48, 14, 9.5, 7, "hair", base=0.55)
    c.ellipse(*FACE, "skin", base=1.0)
    # beard over the lower face, plus a chin that sits 1px under the jaw
    c.ellipse(48, 32.8, 5.6, 2.4, "beard", base=0.9)
    for y in range(14, 36):
        for x in range(38, 58):
            if in_face(x, y) and y >= beard_top(x):
                c.shade_px(x, y, "beard", 0.75 - 0.03 * (y - 25) - 0.04 * max(0, x - 50))
    # stubble transition row
    for x in range(40, 56):
        y = beard_top(x) - 1
        if in_face(x, y) and (x + y) % 2 == 0:
            c.shade_px(x, y, "beard", 0.95)
    # mouth patch is skin; the mouth overlay paints the lips
    for x in range(45, 51):
        c.shade_px(x, 29, "skin", 0.45)
    # nose
    c.shade_px(48, 22, "skin", 1.0)
    c.shade_px(48, 23, "skin", 1.0)
    c.shade_px(49, 24, "skin", 0.35)
    c.shade_px(49, 25, "skin", 0.3)
    c.shade_px(48, 25, "skin", 0.85)
    c.shade_px(47, 26, "skin", 0.3)
    c.shade_px(49, 26, "skin", 0.2)
    c.shade_px(48, 26, "skin", 0.5)
    # cheek shading on the shadow side
    for y in range(18, 25):
        c.shade_px(55, y, "skin", 0.3)
    # curly hair: overlapping sphere-shaded curls
    curls = [
        (38.5, 14.5, 2.6), (41, 11, 3.6), (45, 8.5, 3.8), (50, 8, 3.8), (54.5, 10, 3.4), (57, 13.5, 2.6),
        (47.5, 5.5, 2.6), (42.5, 6.5, 2.4), (52, 5.5, 2.2),
        (43, 13.5, 3.0), (48, 12.5, 3.2), (52.5, 13.5, 3.0),
        (42.5, 16, 1.8), (46.5, 15.4, 1.8), (51, 15.8, 1.7), (55, 16.5, 1.6),
        (39.2, 18, 1.5), (56.8, 18, 1.4),
    ]
    for (cx, cy, r) in curls:
        c.ellipse(cx, cy, r, r * 0.92, "hair", base=1.05)
    # hairline: keep the forehead clear below the fringe curls
    for y in range(17, 24):
        for x in range(41, 56):
            if in_face(x, y) and c.mat[y][x] == "hair":
                fringe = y == 17 and x in (42, 43, 46, 47, 51)
                if not fringe:
                    c.shade_px(x, y, "skin", 0.95 if y > 17 else 0.65)
    # close-cropped sides running into the beard
    for y in range(19, 26):
        c.shade_px(40, y, "hair", 0.5)
        c.shade_px(55, y, "hair", 0.35)
    # a few stray curl pixels on the outline for the messy silhouette
    for (x, y) in [(36, 12), (39, 5), (44, 3), (55, 5), (59, 11), (36, 16)]:
        c.shade_px(x, y, "hair", 0.5)
    return c.render()


# ── face overlays ───────────────────────────────────────────────────
EYE_KEY = {"L": LASH, "W": WHITE, "I": IRIS, "P": PUPIL, "s": SKIN_SHADOW}
EYES = {
    "open": (20, ["LLLL", "WIPW", ".II."]),
    "down": (20, ["ssss", "LLLL", ".IP."]),
    "closed": (21, ["LLLL"]),
    "wide": (19, ["LLLL", "WIPW", "WIIW", ".WW."]),
}

BROW_KEY = {"B": BROW, "b": BROW_SOFT}
BROWS_L = {
    "normal": (18, [".bBB", "B..."]),
    "up": (16, ["..BB", "BB.."]),
    "knit": (18, ["BBB.", "...B"]),
}


def overlay_eyes(frame):
    c = new()
    y0, rows = EYES[frame]
    c.stamp(42, y0, rows, EYE_KEY)
    c.stamp(50, y0, mirror_rows(rows), EYE_KEY)
    return c.render(outline=False)


def overlay_brows(frame):
    c = new()
    if frame == "quirk":
        yl, rl = BROWS_L["normal"]
        yr, rr = BROWS_L["up"]
    else:
        yl, rl = BROWS_L[frame]
        yr, rr = yl, rl
    c.stamp(42, yl, rl, BROW_KEY)
    c.stamp(50, yr, mirror_rows(rr), BROW_KEY)
    return c.render(outline=False)


MOUTH_KEY = {"D": MOUTH_DARK, "l": LIP, "T": TEETH, "k": BEARD_PX, "F": FOOD_PX, "s": SKIN_SHADOW}
MOUTHS = {
    "closed": (28, ["D....D", ".DDDD.", "..ll.."]),
    "chew_a": (28, ["......", ".DDDD.", "..ll.."]),
    "chew_b": (28, ["......", "..DD..", ".llll.", ".kkkk."]),
    "talk_a": (28, ["......", ".DDDD.", "..DD..", "..ll.."]),
    "talk_b": (28, ["......", ".DTTD.", ".DDDD.", "..ll.."]),
    "agape": (28, ["......", ".DTTD.", ".DDDD.", ".DFDD.", ".DDDD.", "..ll..", "kkkkkk", ".kkkk."]),
    "smirk": (28, [".....D", ".DDDD.", "..ll.."]),
}


def overlay_mouth(frame):
    c = new()
    y0, rows = MOUTHS[frame]
    c.stamp(45, y0, rows, MOUTH_KEY)
    return c.render(outline=False)


# ── arms ────────────────────────────────────────────────────────────
ARM_L = {
    "rest": ((26, 60), (32, 79), None, 0),
    "hold": ((26, 60), (36, 66), "wrap", -60),
    "eat": ((27, 59), (37, 41), "wrap", -55),
    "wave_a": ((19, 47), (17, 30), "wrap", -95),
    "wave_b": ((19, 47), (12, 32), "wrap", -120),
    "crumple": ((26, 60), (36, 64), "ball", 0),
    "throw_back": ((20, 44), (25, 28), "ball", 0),
    "throw_release": ((17, 40), (6, 36), None, 0),
}
ARM_R = {
    "rest": ((70, 60), (64, 79), None, 0),
    "phone_up": ((69, 60), (58, 52), "phone_up", 0),
    "phone_low": ((70, 60), (68, 75), "phone_low", 0),
}


def wrap(c, hx, hy, angle_deg):
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    tip = (hx + dx * 8.5, hy + dy * 8.5)
    base = (hx - dx * 2.0, hy - dy * 2.0)
    c.capsule(base, tip, 2.2, 3.0, "paper", base=1.0)
    c.ellipse(tip[0] + dx * 0.8, tip[1] + dy * 0.8, 2.6, 2.3, "food", base=1.05)
    c.px(int(tip[0] + dx * 1.5 - 1), int(tip[1] + dy * 1.5), GREEN_PX)
    c.px(int(tip[0] + dx * 0.5 + 1), int(tip[1] + dy * 0.5 - 1), GREEN_PX)


def arm(side, frame):
    c = new()
    shoulder = SHOULDER_L if side == "l" else SHOULDER_R
    elbow, hand, prop, ang = (ARM_L if side == "l" else ARM_R)[frame]
    base = 0.95 if side == "l" else 0.75
    hx, hy = hand
    ex, ey = elbow
    fl = math.hypot(hx - ex, hy - ey) or 1.0
    ux, uy = (hx - ex) / fl, (hy - ey) / fl
    wrist = (hx - ux * 3.0, hy - uy * 3.0)
    if prop in ("phone_up",):
        c.rect(55, 42, 59, 51, "phone", 0.5)
        for y in range(43, 48):
            c.px(56, y, "#33415a")
            c.px(57, y, "#3d4e6b")
            c.px(58, y, "#33415a")
    if prop == "phone_low":
        c.rect(66, 75, 70, 84, "phone", 0.4)
    c.capsule(shoulder, elbow, 4.7, 4.3, "jacket", base=base)
    c.capsule(elbow, wrist, 4.3, 3.9, "jacket", base=base * 1.05)
    c.capsule((wrist[0] - ux * 2.6, wrist[1] - uy * 2.6), wrist, 4.1, 4.1, "jacket", base=base * 0.6)
    if prop == "wrap":
        wrap(c, hx, hy, ang)
    if frame == "rest":
        c.ellipse(hx, hy - 1, 2.6, 1.6, "skin", base=0.8)
    else:
        c.ellipse(hx, hy, 2.8, 3.0, "skin", base=1.0)
        # knuckle line
        c.shade_px(int(hx), int(hy + 1), "skin", 0.35)
    if prop == "ball":
        c.ellipse(hx + 0.5, hy - 2.0, 2.2, 2.0, "paper", base=1.1)
        c.px(int(hx), int(hy - 2), "#a39c91")
    if prop == "wrap" and frame == "eat":
        # fingers wrap round the paper
        c.shade_px(int(hx + 1), int(hy - 2), "skin", 0.8)
    return c.render()


def anchors():
    hands_l = {k: [v[1][0], v[1][1] - (2 if v[2] == "ball" else 0)] for k, v in ARM_L.items()}
    hands_r = {k: list(v[1]) for k, v in ARM_R.items()}
    return {"mouth": list(MOUTH), "neck": list(NECK), "hand_l": hands_l, "hand_r": hands_r}


def build():
    """Returns ({relative_png_path: Image}, manifest_parts)."""
    images = {
        "shadow.png": shadow(),
        "legs.png": legs(),
        "torso.png": torso(),
        "head.png": head(),
    }
    for f in EYES:
        images["eyes_%s.png" % f] = overlay_eyes(f)
    for f in ["normal", "up", "knit", "quirk"]:
        images["brows_%s.png" % f] = overlay_brows(f)
    for f in MOUTHS:
        images["mouth_%s.png" % f] = overlay_mouth(f)
    for f in ARM_L:
        images["arm_l_%s.png" % f] = arm("l", f)
    for f in ARM_R:
        images["arm_r_%s.png" % f] = arm("r", f)
    return images
