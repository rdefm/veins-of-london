"""Mile End Road back alley at night: parallax layers, ambient life, lights, the car.

Drawn in a character-kit style (char_kit.STYLES): the style's scale (art authored
at 1/scale resolution, then enlarged so the set's pixels match the characters'),
its tone ramps (flat fills on the ramp's lit / mid / dark entries) and its
outline (ink line, own-darkest-tone line, or none). Coordinates below are world
pixels; Paint divides them by the scale. Layer images are drawn in their own
parallax coordinates (screen_x = image_x - camera_left * parallax).

Side-on: the back wall of the Mile End Road shops runs across the world; the
alley mouth at the left opens onto the road (passers-by walk past in the far
layer); the right end is where the car drives in. The car parks behind the
cast (drawn as an object back), so the buyers stand in front of it.
"""
import math
import random

from PIL import Image

from char_kit import ramp, render_selout
from raster import Canvas, Material, darken, lerp_c

WORLD_W, WORLD_H = 360, 320
FLOOR_Y = 300            # feet line for actors and the car
WALL_BASE = 264          # back wall meets the ground
WALL_TOP = 96
MOUTH_X = 40             # alley mouth (open to the road) left of this
WALK_Y = 274             # walker feet (far parallax space)
FAR_P, FORE_P = 0.6, 1.25
FORE_W = 440
DOOR_X = 142             # chicken shop back door, left edge
FIRE_X = 286             # fire door, left edge
LAMP_X = 236             # lamp post
VENT = (176, 150)        # extractor vent box, top-left
BIN_X = 52               # pair of commercial bins, left edge
CAT_POS = (60, 207)      # cat on the bin lid (ambient sprite top-left)
STEAM_POS = (174, 116)
CAR_W, CAR_H = 150, 60   # car object: beam ahead (left) + body (right 100 px)
WALK_W, WALK_H = 18, 40
LIT, MID, DARK = 0.99, 0.6, 0.2

COLOURS = {
    "brick": "#6b3d30", "mortar": "#3d2c2a", "coping": "#55565e", "ground": "#5d6273",
    "joint": "#2c2f39", "puddle": "#2a3346", "door": "#4f5a5e", "frame": "#2f3236",
    "fire": "#3f5a4c", "sill": "#6e6a66", "glass": "#2a3550", "lit": "#f2c46e",
    "pipe": "#3a3f47", "iron": "#262a30", "bin": "#3e5c3a", "lid": "#34502f",
    "vent": "#7c8088", "kitchen": "#ffd88a", "sky": "#1a2238", "roof": "#141a28",
    "shop": "#2e2a2e", "sign": "#d8433a", "signtext": "#ffe7a0", "pave": "#4e505c",
    "cat": "#26232a", "steam": "#c9cdd6", "body": "#8d9298", "window": "#1c2433",
    "tyre": "#1d1e22", "hub": "#a4a9b0", "lamp": "#fff1c4", "tail": "#d0342c",
    "coatA": "#2c3140", "coatB": "#5a4a3c", "skin": "#b88a6a", "hair": "#241c18", "legs": "#20232c",
}
# Styles with no outline separate the cast from the set by tone alone: the wall
# sits darker and the bins recede so green jackets don't merge into them.
UNLINED = {"brick": "#55302a", "mortar": "#30232a", "bin": "#26342d", "lid": "#212d27"}


class Paint:
    """A raster Canvas at 1/scale resolution, addressed in world pixels."""

    def __init__(self, style, w, h):
        self.s = style["scale"]
        self.style = style
        self.c = Canvas(-(-w // self.s), -(-h // self.s), materials(style))
        self.w, self.h = w, h

    def _p(self, v):
        return v / self.s

    def poly(self, pts, mat, v=MID):
        self.c.poly([(self._p(x), self._p(y)) for (x, y) in pts], mat, base=v, cyl=False)

    def rect(self, x0, y0, x1, y1, mat, v=MID):
        """Inclusive world rect, snapped to whole canvas pixels."""
        s = self.s
        self.c.rect(int(x0 // s), int(y0 // s), int(x1 // s), int(y1 // s), mat, v)

    def ellipse(self, cx, cy, rx, ry, mat, v=MID):
        self.c.ellipse(self._p(cx), self._p(cy), max(0.6, self._p(rx)), max(0.6, self._p(ry)), mat, base=v, flat=True)

    def dot(self, x, y, mat, v=MID):
        self.c.shade_px(int(x // self.s), int(y // self.s), mat, v)

    def finish(self, outline=True):
        kind = self.style["outline"] if outline else "none"
        img = render_selout(self.c) if kind == "selout" else self.c.render(outline=kind != "none")
        return img.resize((self.w, self.h), Image.NEAREST) if self.s != 1 else img


def materials(style):
    if style["outline"] == "ink":
        line = lambda r: style["ink"]
    else:
        line = lambda r: darken(r[0], 0.62)
    colours = dict(COLOURS)
    if style["outline"] == "none":
        colours.update(UNLINED)
    out = {}
    for k, c in colours.items():
        r = ramp(c, style["tones"])
        out[k] = Material(r, outline=line(r))
    return out


def light_points():
    """World points of the set's lights: lamp post, kitchen door spill, bulkhead over the fire door."""
    return [(LAMP_X, 150), (DOOR_X + 13, 206), (FIRE_X + 14, 176)]


def _lit_at(x, y, reach=1.0):
    """How strongly the alley's lights reach a world point (0..1)."""
    best = 0.0
    for (lx, ly), r in zip(light_points(), (70, 52, 44)):
        d = math.hypot((x - lx) / (r * reach), (y - ly) / (r * reach * 0.9))
        best = max(best, 1.0 - d)
    return best


# ── far layer: sky, rooftops, the road seen through the alley mouth ──
def far_layer(style):
    w, h = WORLD_W, WORLD_H
    p = Paint(style, w, h)
    s = p.s
    p.rect(0, 0, w - 1, 150, "sky", DARK)
    p.rect(0, 108, w - 1, 150, "sky", MID)        # sodium haze low over the roofs
    rng = random.Random(3)
    for (x0, x1, top) in [(0, 46, 70), (46, 96, 84), (96, 150, 62), (150, 214, 78), (214, 262, 58),
                          (262, 318, 80), (318, 360, 66)]:
        p.rect(x0, top, x1, 200, "roof", MID if (x0 // 50) % 2 else DARK)
        cx = x0 + (x1 - x0) // 3
        p.rect(cx, top - 10, cx + 6, top, "roof", DARK)
        for wy in range(top + 8, 196, 14):
            for wx in range(x0 + 5, x1 - 6, 11):
                if rng.random() < 0.18:
                    p.rect(wx, wy, wx + 3, wy + 5, "lit", MID)
    # Mile End Road, across from the alley mouth: shopfront with a lit sign, pavement
    p.rect(-1, 170, 120, 262, "shop", MID)
    p.rect(-1, 176, 120, 190, "sign", LIT)
    for x in range(6, 110, 6 * s):
        p.rect(x, 181, x + 2, 185, "signtext", LIT)
    for x0 in (4, 46, 88):
        p.rect(x0, 200, x0 + 28, 252, "kitchen", MID)
        p.rect(x0 + 13, 200, x0 + 15, 252, "shop", DARK)
    p.rect(-1, 262, w - 1, h - 1, "pave", MID)
    p.rect(-1, 262, w - 1, 263, "pave", LIT)
    return p.finish(outline=False)


# ── alley layer (parallax 1.0) ──────────────────────────────────────
def alley_layer(style):
    w, h = WORLD_W, WORLD_H
    base = Paint(style, w, h)
    s = base.s
    cw, ch = base.c.w, base.c.h
    # brick wall, flat fills; lights lift nearby bricks to the lit tone
    bw, bh = max(3, round(8 / s)), max(2, round(4 / s))
    x_mouth, y_top, y_base = MOUTH_X // s, WALL_TOP // s, WALL_BASE // s
    rng = random.Random(5)
    for y in range(y_top, y_base):
        row = (y - y_top) // bh
        for x in range(x_mouth, cw):
            mortar = (y - y_top) % bh == bh - 1 or (x + (row % 2) * (bw // 2)) % bw == 0
            wx, wy = (x + 0.5) * s, (y + 0.5) * s
            lit = _lit_at(wx, wy)
            if mortar:
                base.c.shade_px(x, y, "mortar", DARK if lit < 0.35 else MID)
            else:
                v = LIT if lit > 0.45 else (MID if lit > 0.05 or rng.random() > 0.25 else DARK)
                base.c.shade_px(x, y, "brick", v)
    base.rect(MOUTH_X, WALL_TOP - 4, w - 1, WALL_TOP, "coping", MID)
    base.rect(MOUTH_X, WALL_TOP - 4, w - 1, WALL_TOP - 4, "coping", LIT)
    base.rect(MOUTH_X, WALL_TOP - 4, MOUTH_X + 5, WALL_BASE, "brick", DARK)   # end pier at the mouth
    # cobbles, wet: puddles pick up the lights
    cb_w, cb_h = max(3, round(9 / s)), max(2, round(5 / s))
    g_top = WALL_BASE // s
    for y in range(g_top, ch):
        row = (y - g_top) // cb_h
        for x in range(cw):
            wx, wy = (x + 0.5) * s, (y + 0.5) * s
            joint = (y - g_top) % cb_h == 0 or (x + (row % 2) * (cb_w // 2)) % cb_w == 0
            lit = _lit_at(wx, wy - 40, 1.3)
            if joint:
                base.c.shade_px(x, y, "joint", MID if lit > 0.3 else DARK)
            else:
                base.c.shade_px(x, y, "ground", LIT if lit > 0.55 else (MID if lit > 0.1 else DARK))
    for (px0, px1, py) in [(110, 168, 304), (196, 262, 290), (300, 344, 310), (8, 44, 296)]:
        for y in range(py, py + 8):
            half = (px1 - px0) / 2 * math.sqrt(max(0.0, 1 - ((y - py - 4) / 4.5) ** 2))
            mx = (px0 + px1) / 2
            for x in range(int(mx - half), int(mx + half) + 1, s):
                lx = min(light_points(), key=lambda q: abs(q[0] - x))[0]
                streak = abs(x - lx) < 4 + 2 * s
                base.dot(x, y, "lit" if streak else "puddle", MID if streak else (MID if y < py + 3 else DARK))
    base.rect(MOUTH_X, WALL_BASE - 2, w - 1, WALL_BASE, "joint", DARK)     # wall foot
    img = base.finish(outline=False)
    for part in (_windows(style), _doors(style), _pipes(style), _bins(style), _lamp(style)):
        img.alpha_composite(part)
    return img


def _windows(style):
    p = Paint(style, WORLD_W, WORLD_H)
    for i, x in enumerate((64, 122, 196, 262, 320)):
        lit = i in (1, 3)
        p.rect(x - 2, 112, x + 23, 147, "frame", MID)
        p.rect(x, 114, x + 21, 145, "lit" if lit else "glass", LIT if lit else MID)
        p.rect(x + 10, 114, x + 11, 145, "frame", DARK)
        p.rect(x, 128, x + 21, 129, "frame", DARK)
        p.rect(x - 3, 147, x + 24, 150, "sill", MID)
    return p.finish()


def _doors(style):
    p = Paint(style, WORLD_W, WORLD_H)
    # chicken shop back door, ajar: kitchen light in the gap and over the step
    x = DOOR_X
    p.rect(x - 3, 176, x + 29, WALL_BASE, "frame", MID)
    p.rect(x, 180, x + 26, WALL_BASE - 1, "kitchen", LIT)
    p.rect(x + 7, 180, x + 26, WALL_BASE - 1, "door", MID)
    p.rect(x + 7, 180, x + 9, WALL_BASE - 1, "door", LIT)
    p.rect(x + 22, 218, x + 23, 222, "frame", DARK)
    p.rect(x - 4, WALL_BASE - 1, x + 30, WALL_BASE + 2, "coping", MID)
    # extractor vent above it
    vx, vy = VENT
    p.rect(vx, vy, vx + 20, vy + 14, "vent", MID)
    for yy in range(vy + 3, vy + 13, 3):
        p.rect(vx + 2, yy, vx + 18, yy, "vent", DARK)
    p.rect(vx + 8, vy + 14, vx + 11, WALL_BASE - 30, "pipe", MID)
    # fire door with a bulkhead light
    x = FIRE_X
    p.rect(x - 3, 182, x + 31, WALL_BASE, "frame", MID)
    p.rect(x, 186, x + 13, WALL_BASE - 1, "fire", MID)
    p.rect(x + 15, 186, x + 28, WALL_BASE - 1, "fire", DARK)
    p.rect(x + 3, 222, x + 25, 224, "iron", MID)
    p.rect(x + 9, 172, x + 19, 178, "lamp", LIT)
    p.rect(x + 9, 178, x + 19, 179, "frame", DARK)
    return p.finish()


def _pipes(style):
    p = Paint(style, WORLD_W, WORLD_H)
    for x in (108, 254, 348):
        p.rect(x, WALL_TOP, x + 3, WALL_BASE - 4, "pipe", MID)
        p.rect(x, WALL_TOP, x, WALL_BASE - 4, "pipe", LIT)
        for y in range(WALL_TOP + 20, WALL_BASE - 10, 40):
            p.rect(x - 1, y, x + 4, y + 2, "iron", MID)
        p.rect(x, WALL_BASE - 6, x + 7, WALL_BASE - 3, "pipe", MID)
    return p.finish()


def _bins(style):
    """Two green commercial bins against the wall by the mouth."""
    p = Paint(style, WORLD_W, WORLD_H)
    for i, x in enumerate((BIN_X, BIN_X + 34)):
        top = 226 + i * 4
        p.rect(x, top, x + 30, WALL_BASE + 4, "bin", MID)
        p.rect(x, top, x + 3, WALL_BASE + 4, "bin", LIT)
        p.rect(x - 2, top - 4, x + 32, top, "lid", MID)
        p.rect(x + 6, top + 10, x + 24, top + 12, "lid", DARK)
        p.ellipse(x + 5, WALL_BASE + 6, 3, 3, "tyre", MID)
        p.ellipse(x + 25, WALL_BASE + 6, 3, 3, "tyre", MID)
    return p.finish()


def _lamp(style):
    p = Paint(style, WORLD_W, WORLD_H)
    x = LAMP_X
    p.rect(x - 2, 156, x + 2, WALL_BASE + 6, "iron", MID)
    p.rect(x - 2, 156, x - 2, WALL_BASE + 6, "iron", LIT)
    p.rect(x - 5, WALL_BASE, x + 5, WALL_BASE + 8, "iron", MID)
    p.poly([(x - 7, 142), (x + 7, 142), (x + 5, 156), (x - 5, 156)], "lamp", LIT)
    p.rect(x - 8, 139, x + 8, 142, "iron", MID)
    p.rect(x - 3, 135, x + 3, 139, "iron", DARK)
    p.rect(x - 6, 156, x + 6, 158, "iron", MID)
    return p.finish()


# ── fore layer (parallax 1.25) ──────────────────────────────────────
def fore_layer(style):
    p = Paint(style, FORE_W, WORLD_H)
    # bollard by the mouth, and a lip of kerb and litter along the bottom edge
    x = 46
    p.rect(x, 262, x + 9, WORLD_H - 1, "iron", MID)
    p.rect(x, 262, x + 2, WORLD_H - 1, "iron", LIT)
    p.rect(x - 1, 258, x + 10, 263, "iron", DARK)
    p.rect(x, 274, x + 9, 276, "lit", MID)
    p.rect(-1, 314, FORE_W - 1, WORLD_H - 1, "joint", DARK)
    for (lx, ly, lw) in [(110, 312, 6), (204, 313, 5), (318, 311, 7)]:
        p.rect(lx, ly, lx + lw, ly + 2, "sill", MID)
    return p.finish()


# ── sprites ─────────────────────────────────────────────────────────
def glow():
    n = 33
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    c = n // 2
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c) / c
            if d <= 1:
                px[x, y] = (255, 186, 96, int(120 * (1 - d) ** 2))
    return img


def steam_frame(style, f):
    """Kitchen extractor steam: frame 0 a wisp, 1–2 puffs drifting up."""
    p = Paint(style, 24, 34)
    puffs = [[(12, 30, 3, 2)], [(11, 26, 4, 3), (13, 18, 3, 2)], [(12, 22, 5, 4), (10, 12, 4, 3), (13, 4, 3, 2)]][f]
    for (cx, cy, rx, ry) in puffs:
        p.ellipse(cx, cy, rx, ry, "steam", LIT if cy > 16 else MID)
    img = p.finish(outline=False)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (r, g, b, 120 if y > 16 else 80)
    return img


def cat_frame(style, f):
    """Cat sitting on the bin lid, facing left: 0 still, 1 tail up, 2 head turned."""
    p = Paint(style, 20, 16)
    p.ellipse(11, 10, 5, 5, "cat", MID)
    p.ellipse(6 if f != 2 else 8, 5, 3, 3, "cat", MID)
    hx = 6 if f != 2 else 8
    p.poly([(hx - 3, 4), (hx - 2, 0), (hx - 1, 3)], "cat", MID)
    p.poly([(hx + 1, 3), (hx + 2, 0), (hx + 3, 4)], "cat", MID)
    p.dot(hx - 1 if f != 2 else hx + 1, 5, "lit", LIT)
    if f == 1:
        p.rect(15, 3, 16, 10, "cat", DARK)
        p.rect(16, 2, 17, 3, "cat", DARK)
    else:
        p.rect(14, 14, 19, 15, "cat", DARK)
    return p.finish()


def walker_frame(style, coat, f):
    """Passer-by on Mile End Road, walking right; 4-frame stride."""
    p = Paint(style, WALK_W, WALK_H)
    sw = math.sin(f / 4.0 * 2 * math.pi)
    bob = 0 if f % 2 == 0 else -1
    for sgn in (-1, 1):
        fx = 9 + 4 * sw * sgn
        p.poly([(8, 24 + bob), (11, 24 + bob), (fx + 1.5, 38), (fx - 1.5, 38)], "legs", MID if sgn < 0 else DARK)
    p.poly([(5, 11 + bob), (13, 11 + bob), (14, 27 + bob), (4, 27 + bob)], coat, MID)
    p.ellipse(9.5, 6 + bob, 3.2, 3.6, "skin", MID)
    p.ellipse(9, 4 + bob, 3.4, 2.4, "hair", MID)
    img = p.finish()
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = lerp_c((r, g, b, a), (40, 44, 64, a), 0.3)   # sits back in the dark
    return img


WALKERS = {"walker_a": "coatA", "walker_b": "coatB"}


def vial(style):
    p = Paint(style, 6, 6)
    p.rect(2, 1, 3, 4, "glass", LIT)
    p.rect(2, 3, 3, 4, "steam", MID)
    p.dot(2, 0, "frame", MID)
    return p.finish()


# ── the car: grey Vauxhall hatchback, side-on, facing left ──────────
def car(style):
    """Body plus the headlight beam on the ground ahead of it (left)."""
    back = Image.new("RGBA", (CAR_W, CAR_H), (0, 0, 0, 0))
    px = back.load()
    s = style["scale"]
    for y in range(0, CAR_H, s):
        for x in range(0, 52, s):
            top = 36 + (52 - x) * 0.32
            if top - (52 - x) * 0.12 <= y <= min(CAR_H - 1, 40 + (52 - x) * 0.45):
                a = 70 if y > 50 or x > 30 else 40
                for yy in range(y, min(CAR_H, y + s)):
                    for xx in range(x, min(CAR_W, x + s)):
                        px[xx, yy] = (255, 236, 170, a)
    p = Paint(style, CAR_W, CAR_H)
    o = 50   # body's front bumper x
    body = [(o, 36), (o + 2, 31), (o + 14, 29), (o + 32, 27), (o + 46, 14), (o + 80, 12), (o + 94, 20),
            (o + 99, 28), (o + 100, 46), (o + 96, 49), (o + 2, 49), (o, 46)]
    p.poly(body, "body", MID)
    p.poly([(o + 2, 31), (o + 14, 29), (o + 32, 27), (o + 46, 14), (o + 80, 12), (o + 94, 20), (o + 94, 24),
            (o + 2, 34)], "body", LIT)
    p.poly([(o + 36, 27), (o + 47, 16), (o + 62, 15), (o + 62, 27)], "window", MID)
    p.poly([(o + 65, 15), (o + 79, 14), (o + 89, 21), (o + 89, 27), (o + 65, 27)], "window", MID)
    p.rect(o + 63, 15, o + 64, 46, "frame", DARK)
    p.rect(o + 35, 27, o + 35, 46, "frame", DARK)
    p.rect(o + 90, 27, o + 90, 44, "frame", DARK)
    p.rect(o + 2, 40, o + 99, 41, "body", DARK)
    for hx in (o + 52, o + 78):
        p.rect(hx, 31, hx + 4, 31, "frame", DARK)
    p.rect(o + 30, 26, o + 33, 28, "frame", MID)                         # wing mirror
    p.rect(o, 33, o + 4, 37, "lamp", LIT)                               # headlight
    p.rect(o, 41, o + 3, 46, "frame", DARK)                             # bumper grille
    p.rect(o + 97, 28, o + 99, 34, "tail", LIT)                         # tail light
    for wx in (o + 18, o + 82):
        p.ellipse(wx, 49, 9, 9, "body", DARK)                           # arch
        p.ellipse(wx, 50, 8, 8, "tyre", MID)
        p.ellipse(wx, 50, 4, 4, "hub", MID)
    back.alpha_composite(p.finish())
    return back


def build(style):
    images = {
        "far.png": far_layer(style),
        "alley.png": alley_layer(style),
        "fore.png": fore_layer(style),
        "glow.png": glow(),
        "vial.png": vial(style),
    }
    images["car.png"] = car(style)
    for i in range(3):
        images["steam_%d.png" % i] = steam_frame(style, i)
        images["cat_%d.png" % i] = cat_frame(style, i)
    for kind, coat in WALKERS.items():
        for i in range(4):
            images["%s_%d.png" % (kind, i)] = walker_frame(style, coat, i)
    return images


def manifest(style, set_id):
    walker_frames = lambda k: ["%s_%d.png" % (k, i) for i in range(4)]
    return {
        "id": set_id,
        "dir": "res://assets/stages/sets/%s/" % set_id,
        "design_size": [180, 240],
        "world": [WORLD_W, WORLD_H],
        "floor_y": FLOOR_Y,
        "layers": [
            {"id": "far", "file": "far.png", "parallax": FAR_P, "slot": "back"},
            {"id": "alley", "file": "alley.png", "parallax": 1.0, "slot": "mid"},
            {"id": "fore", "file": "fore.png", "parallax": FORE_P, "slot": "front"},
        ],
        "walkers": {
            "parallax": FAR_P, "feet_y": WALK_Y, "size": [WALK_W, WALK_H], "frame_time": 0.18,
            "range": [-24, 64],
            "list": [
                {"frames": walker_frames("walker_a"), "x": 10, "speed": 10, "dir": 1},
                {"frames": walker_frames("walker_b"), "x": 50, "speed": 8, "dir": -1},
            ],
        },
        "ambient": [
            {"id": "steam", "frames": ["steam_0.png", "steam_1.png", "steam_2.png"], "pos": list(STEAM_POS),
             "hold": [[1.2, 2.4], [0.4, 0.6], [0.4, 0.7]]},
            {"id": "cat", "frames": ["cat_0.png", "cat_1.png", "cat_2.png"], "pos": list(CAT_POS),
             "hold": [[2.5, 5.0], [0.6, 1.0], [1.2, 2.2]]},
        ],
        "lights": {"file": "glow.png", "points": [list(p) for p in light_points()]},
        "objects": {
            "car": {"x": 200, "back": "car.png", "size": [CAR_W, CAR_H]},
        },
        "props": {"vial": "vial.png"},
    }
