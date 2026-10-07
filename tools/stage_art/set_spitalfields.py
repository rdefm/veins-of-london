"""Spitalfields Market stage set: parallax layers, ambient sprites, props.

World is WORLD_W x WORLD_H; layer images are drawn in their own parallax
coordinates (screen_x = image_x - camera_left * parallax).
"""
import math
import random

from PIL import Image

from raster import BAYER4, Canvas, Material, hexc, lerp_c

WORLD_W, WORLD_H = 360, 320
FLOOR_Y = 300            # feet line for actors and the bin
SEAM_Y = 236             # market floor starts here; far floor shows above it
WALK_Y = 232             # walker feet (far parallax space)
FAR_P, FORE_P = 0.6, 1.25
FORE_W = 440
STALL_X = 34            # falafel stall drawn in local coords, shifted into place
VENDOR_POS = (STALL_X + 66, 150)

rng = random.Random(7)


def new_img(w, h, color=(0, 0, 0, 0)):
    return Image.new("RGBA", (w, h), color)


def put(px, w, h, x, y, c):
    if 0 <= x < w and 0 <= y < h:
        px[x, y] = hexc(c) if isinstance(c, str) else c


def fill_rect(px, w, h, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(h, y1 + 1)):
        for x in range(max(0, x0), min(w, x1 + 1)):
            put(px, w, h, x, y, c)


def dither_pick(a, b, t, x, y):
    return a if (BAYER4[y % 4][x % 4] / 16.0) >= t else b


# ── far layer ───────────────────────────────────────────────────────
def far_layer():
    w, h = WORLD_W, WORLD_H
    img = new_img(w, h, hexc("#000000"))
    px = img.load()
    sky = ["#1f2b44", "#2c3d5c", "#3e5677", "#57708f", "#7a8ca3", "#a39a9a", "#c8a487"]
    for y in range(0, 140):
        t = y / 139 * (len(sky) - 1)
        i = int(t)
        f = t - i
        for x in range(w):
            c = sky[min(i + (1 if (BAYER4[y % 4][x % 4] / 16.0) < f else 0), len(sky) - 1)]
            put(px, w, h, x, y, c)
    iron = "#161a20"
    iron_hi = "#2c333c"
    # glass roof mullions and transoms
    for x in range(0, w, 16):
        for y in range(0, 100):
            put(px, w, h, x, y, iron)
    for y in range(6, 100, 13):
        for x in range(w):
            put(px, w, h, x, y, iron)
    # main roof arches
    for cx in (60, 180, 300):
        for xx in range(-62, 63):
            yy = int(10 + 0.012 * xx * xx)
            for t in range(3):
                put(px, w, h, cx + xx, yy + t, iron if t else iron_hi)
    # lattice girder
    for y in (94, 95, 112, 113):
        for x in range(w):
            put(px, w, h, x, y, iron)
    for x0 in range(0, w, 12):
        for k in range(17):
            put(px, w, h, x0 + k * 12 // 17, 96 + k, iron)
            put(px, w, h, x0 + 12 - k * 12 // 17, 96 + k, iron)
    # brick facade
    brick = ["#5e2a1f", "#74331f", "#8a4029", "#9c4d31"]
    for y in range(114, 216):
        row = (y - 114) // 3
        for x in range(w):
            mortar = (y - 114) % 3 == 2 or (x + (row % 2) * 4) % 8 == 0
            if mortar:
                c = "#4a3a33"
            else:
                bi = ((x + (row % 2) * 4) // 8 * 31 + row * 17) % 7
                c = brick[min(3, bi % 4)]
            # haze toward the floor: the far wall sits in warm dusk light
            c = lerp_c(c, "#c79a6e", 0.15 + 0.25 * (y - 114) / 102)
            put(px, w, h, x, y, c)
    # arched windows
    for cx in (40, 120, 200, 280):
        for y in range(122, 204):
            for x in range(cx - 15, cx + 16):
                dx = x - cx
                top = 136 - math.sqrt(max(0, 15 * 15 - dx * dx)) * 0.95
                if y < top:
                    continue
                edge = abs(dx) >= 14 or y < top + 1.5 or y >= 202
                if edge:
                    c = "#d9c2a2"
                elif dx % 6 == 0 or (y - 140) % 9 == 0:
                    c = "#20252c"
                else:
                    lit = ((dx // 6) * 7 + (y // 9) * 3 + cx) % 5 == 0
                    c = "#d9a35a" if lit else lerp_c("#2b3a52", "#4a5a72", (y - 122) / 82)
                put(px, w, h, x, y, c)
    # iron columns
    for cx in (0, 80, 160, 240, 320):
        for y in range(96, 222):
            for x in range(cx - 2, cx + 3):
                c = "#2c3a33" if x == cx - 1 else ("#121815" if x == cx + 2 else "#1d2722")
                put(px, w, h, x, y, c)
        fill_rect(px, w, h, cx - 4, 114, cx + 4, 117, "#1d2722")
    # far stall canopies + goods, low contrast
    canopy = ["#d8cdb8", "#b9ae9a"]
    for i, (x0, x1) in enumerate([(4, 52), (58, 110), (168, 214), (220, 270), (300, 352)]):
        for y in range(176, 188):
            for x in range(x0, x1):
                peak = abs(((x - x0) % 16) - 8)
                if y - 176 < peak // 2:
                    continue
                put(px, w, h, x, y, canopy[(y > 184)])
        goods = ["#8d4a3a", "#3f5d6e", "#9b7a3a", "#5b4a6a", "#6b7f4a"]
        for x in range(x0 + 2, x1 - 2):
            for y in range(188, 214):
                g = goods[((x - x0) // 5 + i) % len(goods)]
                c = lerp_c(g, "#9a8070", 0.45)
                if (y - 188) % 9 == 0:
                    c = "#4a3c34"
                put(px, w, h, x, y, c)
        fill_rect(px, w, h, x0, 214, x1, 222, "#3e3430")
    # distant string of lights
    for x in range(0, w, 7):
        y = int(168 + 4 * math.sin(x / 23.0))
        put(px, w, h, x, y, "#ffd690")
        put(px, w, h, x, y - 1, "#3a2d22")
    # back floor
    for y in range(222, h):
        for x in range(w):
            t = (y - 222) / (h - 222)
            c = lerp_c("#7d6f63", "#968676", t)
            if (y - 222) in (5, 12) or ((x * 7 + (y // 6) * 13) % 37 == 0):
                c = lerp_c(c, "#5b5048", 0.6)
            put(px, w, h, x, y, c)
    return img


# ── market layer (parallax 1.0) ─────────────────────────────────────
def catenary(x0, y0, x1, y1, sag, step):
    pts = []
    n = max(1, int((x1 - x0) / step))
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + sag * 4 * t * (1 - t)
        pts.append((x, y))
    return pts


WIRES = [((-6, 104), (176, 118), 14), ((176, 118), (366, 98), 12)]


def market_layer():
    w, h = WORLD_W, WORLD_H
    img = new_img(w, h)
    px = img.load()
    # floor flags with perspective joints toward a vanishing point
    rows = [SEAM_Y, 242, 250, 260, 273, 290, 312, 340]
    vx, vy = 180, 120
    stones = ["#8b7f72", "#958878", "#827669", "#9a8c7c", "#8f8173"]
    for y in range(SEAM_Y, h):
        r = max(i for i, ry in enumerate(rows) if ry <= y)
        for x in range(w):
            # project x onto the bottom edge to find the joint column
            bx = vx + (x - vx) * (340 - vy) / max(1, (y - vy))
            col = int(math.floor((bx + (r % 2) * 22) / 44))
            c = stones[(col * 3 + r * 5) % len(stones)]
            # speckle
            if rng.random() < 0.05:
                c = lerp_c(c, "#6e6358", 0.5)
            # joints
            jb = (bx + (r % 2) * 22) % 44
            if y in rows or jb < 44 * 0.025 * (1 + (y - SEAM_Y) / 40):
                c = "#5f554c"
            # warm light pools
            for (lx, ly, lr) in [(94, 262, 70), (230, 300, 80), (320, 260, 60)]:
                d = ((x - lx) / lr) ** 2 + ((y - ly) / (lr * 0.35)) ** 2
                if d < 1:
                    c = lerp_c(c, "#d8b285", 0.3 * (1 - d))
            put(px, w, h, x, y, c)
    for x in range(w):
        put(px, w, h, x, SEAM_Y, "#3b332d")
        put(px, w, h, x, SEAM_Y + 1, "#a89886")
    img.alpha_composite(stall_img(), (STALL_X, 0))
    px = img.load()
    clothing(px, w, h)
    # light wires
    for (a, b, sag) in WIRES:
        for (x, y) in catenary(a[0], a[1], b[0], b[1], sag, 1):
            put(px, w, h, int(x), int(y), "#1a1512")
    for (x, y) in light_positions():
        put(px, w, h, x, y - 1, "#1a1512")
        put(px, w, h, x, y, "#ffe9b0")
        put(px, w, h, x, y + 1, "#ffcf70")
        put(px, w, h, x + 1, y, "#f0b860")
    # hanging bulb inside the stall
    fill_rect(px, w, h, STALL_X + 56, 160, STALL_X + 56, 166, "#1a1512")
    return img


def stall_img():
    """Falafel stall in local coords; market_layer() shifts it by STALL_X."""
    w, h = WORLD_W, WORLD_H
    img = new_img(w, h)
    px = img.load()
    for x0 in (4, 112):
        fill_rect(px, w, h, x0, 132, x0 + 2, 250, "#1d2320")
        put(px, w, h, x0, 132, "#3a443e")
    # interior back
    fill_rect(px, w, h, 6, 150, 112, 205, "#2e2621")
    for y in (166, 182):
        fill_rect(px, w, h, 8, y, 110, y + 1, "#5a4433")
        for x in range(10, 108, 6):
            jar = ["#b6863f", "#7f9a4a", "#b94a3a", "#d6c08a"][(x // 6) % 4]
            fill_rect(px, w, h, x, y - 5, x + 3, y - 1, jar)
            put(px, w, h, x, y - 5, "#e8dcc0")
    # awning
    for y in range(126, 160):
        t = (y - 126) / 33
        xl, xr = int(-2 - 4 * t), int(118 + 8 * t)
        for x in range(xl, xr + 1):
            stripe = ((x - int(6 * t)) // 9) % 2
            c = "#2a7058" if stripe else "#1f5a48"
            if y < 129:
                c = "#3d8a70" if stripe else "#2f7560"
            if y > 155:
                c = lerp_c(c, "#0e2a22", 0.4)
            put(px, w, h, x, y, c)
    for x in range(-6, 128):
        scal = 160 + (2 if (x // 4) % 2 else 0)
        for y in range(158, scal + 1):
            put(px, w, h, x, y, "#1a4d3e")
        put(px, w, h, x, scal + 1, "#0e2a22")
    # counter + produce
    fill_rect(px, w, h, 4, 200, 116, 205, "#8a6a48")
    fill_rect(px, w, h, 4, 200, 116, 200, "#b08b62")
    fill_rect(px, w, h, 8, 192, 112, 199, "#c9c3b8")
    for x in range(10, 50, 3):
        for row in (0, 1):
            cx, cy = x + row, 194 + row * 3
            for (dx, dy, c) in [(0, 0, "#7a4a22"), (1, 0, "#98622e"), (0, 1, "#5a3215"), (1, 1, "#7a4a22"), (0, -1, "#b47c3e")]:
                put(px, w, h, cx + dx, cy + dy, c)
    for x in range(52, 80):
        for y in range(193, 199):
            if (x * 3 + y * 5) % 4:
                put(px, w, h, x, y, ["#4f7a2c", "#6b9a3a", "#3c5e22"][(x + y) % 3])
    for x in range(82, 108):
        for y in range(194, 199):
            put(px, w, h, x, y, ["#c0486a", "#d8688a", "#9a3352"][(x * 2 + y) % 3] if (x + y) % 5 else "#e8dcc0")
    # kilim counter front
    pal = ["#2d3f7a", "#a8352e", "#c99a3a", "#e6d8b8", "#1e2a50"]
    for y in range(206, 252):
        for x in range(4, 117):
            dx = (x - 4) % 18 - 9
            dy = (y - 206) % 16 - 8
            d = abs(dx) + abs(dy)
            if d < 3:
                c = pal[2]
            elif d < 5:
                c = pal[1]
            elif d < 7:
                c = pal[3]
            elif (y - 206) % 16 in (0, 15):
                c = pal[4]
            else:
                c = pal[0]
            if y > 246:
                c = lerp_c(c, "#000000", 0.35)
            put(px, w, h, x, y, c)
    fill_rect(px, w, h, 4, 252, 117, 253, "#2a201a")
    # crates by the stall
    for (x0, y0) in [(118, 228), (130, 236)]:
        for y in range(y0, y0 + 16):
            for x in range(x0, x0 + 16):
                c = "#9a7346" if (y - y0) % 5 else "#5e4129"
                if x in (x0, x0 + 15):
                    c = "#5e4129"
                put(px, w, h, x, y, c)
    for x in range(120, 144, 2):
        put(px, w, h, x, 227, "#c47a2a")
        put(px, w, h, x + 1, 226, "#e09a3a")
    return img


def clothing(px, w, h):
    """Right side: clothing rail under white canopies."""
    for y in range(128, 152):
        for x in range(258, 362):
            k = (x - 258) % 34
            peak = abs(k - 17)
            if (y - 128) < peak * 0.7:
                continue
            c = "#ece5d6" if k < 17 else "#cfc6b4"
            if y > 148:
                c = "#b8ad99"
            put(px, w, h, x, y, c)
    for x in (262, 358):
        fill_rect(px, w, h, x, 150, x + 1, 248, "#c9c6c0")
    fill_rect(px, w, h, 262, 161, 360, 162, "#8a8f96")
    garments = ["#2e7c80", "#c49a2c", "#a84a2c", "#2c3a66", "#6e3a63", "#7a8c5a", "#b46e7a", "#3d6a4a"]
    x = 266
    gi = 0
    while x < 354:
        gw = 6 + (gi * 5) % 4
        gh = 44 + (gi * 7) % 14
        base = garments[gi % len(garments)]
        for yy in range(163, 163 + gh):
            for xx in range(x, min(354, x + gw)):
                t = (xx - x) / max(1, gw - 1)
                c = lerp_c(base, "#000000", 0.35 * t) if t > 0.6 else (lerp_c(base, "#ffffff", 0.15) if t < 0.2 else hexc(base))
                put(px, w, h, xx, yy, c)
        put(px, w, h, x + gw // 2, 162, "#d0d4d8")
        x += gw - 1
        gi += 1
    fill_rect(px, w, h, 262, 222, 360, 248, "#3a3330")
    for xx in range(262, 361):
        put(px, w, h, xx, 222, "#57504b")


def light_positions():
    out = []
    for (a, b, sag) in WIRES:
        for (x, y) in catenary(a[0], a[1], b[0], b[1], sag, 11)[1:-1]:
            out.append((int(x), int(y) + 2))
    out.append((STALL_X + 56, 168))
    return out


# ── fore layer (parallax 1.25) ──────────────────────────────────────
def fore_layer():
    w, h = FORE_W, WORLD_H
    img = new_img(w, h)
    px = img.load()
    # iron column
    for y in range(0, h):
        for x in range(350, 360):
            t = (x - 350) / 9
            c = lerp_c("#34443b", "#0d120f", t)
            if x == 351:
                c = hexc("#4c5e52")
            put(px, w, h, x, y, c)
    for (y0, y1, x0, x1) in [(276, 320, 346, 364), (270, 276, 348, 362), (40, 46, 347, 363)]:
        for y in range(y0, y1):
            for x in range(x0, x1):
                t = (x - x0) / max(1, x1 - x0 - 1)
                put(px, w, h, x, y, lerp_c("#3c4c42", "#0d120f", t))
    # planter box with a shrub
    for y in range(282, 320):
        for x in range(150, 200):
            c = "#6e4f2e" if (y - 282) % 8 else "#4a321c"
            if x in (150, 199):
                c = "#3a2614"
            put(px, w, h, x, y, lerp_c(c, "#000000", 0.25))
    leaf = ["#1f3a1a", "#2e5224", "#3f6a2c", "#5a8638"]
    r2 = random.Random(11)
    for _ in range(2600):
        x = r2.randint(146, 204)
        y = r2.randint(236, 286)
        dx = (x - 175) / 30
        dy = (y - 286) / 50
        if dx * dx + dy * dy > 1:
            continue
        shade = 3 if (x < 172 and y < 262) else (2 if x < 185 else 1)
        if r2.random() < 0.3:
            shade = max(0, shade - 1)
        put(px, w, h, x, y, lerp_c(leaf[shade], "#000000", 0.2))
    return img


# ── sprites ─────────────────────────────────────────────────────────
def glow():
    n = 17
    img = new_img(n, n)
    px = img.load()
    c = n // 2
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c) / c
            if d <= 1:
                a = int(150 * (1 - d) ** 2)
                px[x, y] = (255, 190, 110, a)
    return img


WALKER_MATS = {
    "skin": Material(["#7a4f37", "#9c6a4a", "#b88560"], outline="#4a2e20"),
    "hair": Material(["#1f1611", "#33251c", "#4a3628"], outline="#140d09"),
    "coatA": Material(["#1c2333", "#28324a", "#36435f"], outline="#11151f"),
    "coatB": Material(["#6b5a46", "#8c7860", "#a8937a"], outline="#3e3428"),
    "coatC": Material(["#242424", "#333333", "#454545"], outline="#141414"),
    "legs": Material(["#1a1d26", "#262a36", "#343a4a"], outline="#0e1015"),
    "jeans": Material(["#2a3a5a", "#3a4e74", "#4c6290"], outline="#18223a"),
    "bag": Material(["#4a3a2a", "#6b5640", "#8a7256"], outline="#2a2016"),
    "tote": Material(["#bfb39a", "#d9ceb6", "#ece4d0"], outline="#7a705e"),
    "scarf": Material(["#7a1e22", "#9e2a2e", "#c03a3a"], outline="#4a1012"),
    "shoe": Material(["#2a1c14", "#3e2a1e", "#5a3e2a"], outline="#160e0a"),
    "cap": Material(["#1e2a22", "#2c3c30", "#3e5242"], outline="#101812"),
}

WALKERS = {
    "walker_a": dict(coat="coatA", legs="jeans", extra="bag", hair_long=False),
    "walker_b": dict(coat="coatB", legs="legs", extra="scarf", hair_long=True),
    "walker_c": dict(coat="coatC", legs="legs", extra="tote", hair_long=True),
}
WALK_W, WALK_H = 24, 50


def walker_frame(kind, f):
    spec = WALKERS[kind]
    c = Canvas(WALK_W, WALK_H, WALKER_MATS)
    phase = f / 4.0 * 2 * math.pi
    sw = math.sin(phase)
    hip = (12, 30)
    bob = 0 if f % 2 == 0 else -1
    # far leg, far arm first
    for sgn, base in ((-1, 0.55), (1, 0.95)):
        foot = (12 + 5 * sw * sgn, 47)
        c.capsule((hip[0], hip[1] + bob), foot, 2.2, 1.8, spec["legs"], base=base)
        c.ellipse(foot[0] + 1, 47.5, 2.2, 1.3, "shoe", base=base)
        if sgn == -1:
            hand = (12 - 4 * sw, 31 + bob)
            c.capsule((12, 16 + bob), hand, 1.8, 1.6, spec["coat"], base=0.5)
    c.poly([(8, 14 + bob), (16, 14 + bob), (17, 33 + bob), (7, 33 + bob)], spec["coat"], base=0.9, peak=0.35)
    hand = (12 + 4 * sw, 31 + bob)
    c.capsule((12, 16 + bob), hand, 1.8, 1.6, spec["coat"], base=1.0)
    c.ellipse(hand[0], hand[1] + 1, 1.3, 1.3, "skin", base=0.9)
    c.ellipse(12.5, 9 + bob, 3.6, 4.2, "skin", base=1.0)
    c.ellipse(11.5, 7 + bob, 3.8, 3.2, "hair", base=0.9)
    if spec["hair_long"]:
        c.capsule((10, 7 + bob), (9.5, 15 + bob), 2.4, 2.0, "hair", base=0.8)
    if spec["extra"] == "bag":
        c.poly([(5, 15 + bob), (9, 15 + bob), (9, 27 + bob), (5, 27 + bob)], "bag", base=0.9)
    elif spec["extra"] == "scarf":
        c.poly([(9, 13 + bob), (16, 13 + bob), (16, 16 + bob), (9, 16 + bob)], "scarf", base=1.0, cyl=False)
        c.poly([(14, 15 + bob), (16, 15 + bob), (16, 24 + bob), (14, 24 + bob)], "scarf", base=0.8, cyl=False)
    elif spec["extra"] == "tote":
        c.poly([(13, 27 + bob), (19, 27 + bob), (19, 35 + bob), (13, 35 + bob)], "tote", base=1.0)
    img = c.render()
    # push into the haze: distant figures sit back in the warm air
    p = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = p[x, y]
            if a:
                p[x, y] = lerp_c((r, g, b, a), (150, 120, 100, a), 0.22)
    return img


VENDOR_MATS = {
    "skin": Material(["#5a3a26", "#7a5036", "#9a6a4a", "#b48260"], outline="#3a2418"),
    "beard": Material(["#1e1610", "#2e2218", "#3e3022"], outline="#120c08", dither=0.3),
    "cap": Material(["#14181e", "#1e242c", "#2a323c"], outline="#0a0c10"),
    "top": Material(["#1c2230", "#283044", "#343e56"], outline="#10131a"),
    "apron": Material(["#5a4636", "#76604a", "#8e7860"], outline="#3a2c20"),
    "food": Material(["#4f2b12", "#73441f", "#98622e"], outline="#331b09"),
    "steel": Material(["#7a7e84", "#a8acb2", "#cfd2d6"], outline="#4a4e54"),
}


def vendor_frame(f):
    c = Canvas(44, 52, VENDOR_MATS)
    look = f == 2
    c.poly([(9, 22), (35, 22), (38, 52), (6, 52)], "top", base=0.85, peak=0.3)
    c.poly([(14, 26), (30, 26), (32, 52), (12, 52)], "apron", base=0.9, peak=0.4)
    c.rect(19, 15, 25, 22, "skin", 0.4)
    hx = 22 + (2 if look else 0)
    c.ellipse(hx, 11, 6.2, 7.2, "skin", base=0.95)
    c.ellipse(hx, 15.5, 5.2, 3.2, "beard", base=0.9)
    c.ellipse(hx - 0.5, 6, 6.8, 3.6, "cap", base=1.0)
    c.rect(hx - 9 if not look else hx - 3, 7, hx - 2 if not look else hx + 8, 8, "cap", 0.4)
    ex = hx - 3
    c.px(ex, 11, "#140a06")
    c.px(ex + 5, 11, "#140a06")
    if f == 1:
        # scooping falafel with tongs, arm forward
        c.capsule((32, 25), (37, 33), 3.0, 2.6, "top", base=0.9)
        c.ellipse(38, 35, 2.2, 2.2, "skin", base=0.9)
        c.capsule((38, 37), (41, 41), 0.8, 0.8, "steel", base=1.0)
        c.ellipse(41, 40, 1.6, 1.6, "food", base=1.0)
    else:
        c.capsule((32, 25), (34, 44), 3.0, 2.6, "top", base=0.85)
        c.ellipse(34, 46, 2.2, 2.2, "skin", base=0.9)
    c.capsule((12, 25), (10, 44), 3.0, 2.6, "top", base=0.6)
    # cropped at the counter line: the vendor stands behind the produce trays
    return c.render().crop((0, 0, 44, 42))


PROP_MATS = {
    "food": Material(["#4f2b12", "#73441f", "#98622e", "#b47c3e"], outline="#2a1608"),
    "paper": Material(["#8d877d", "#bdb6aa", "#e2dccf", "#f7f3eb"], outline="#5a554d"),
    "bin": Material(["#0d0e10", "#16181b", "#202328", "#2c3036"], outline="#060607"),
    "gold": Material(["#6a4e1a", "#9a7428", "#c99a3a", "#e8c060"], outline="#3a2a0a"),
}


def crumb():
    c = Canvas(5, 5, PROP_MATS)
    c.ellipse(2.5, 2.5, 1.7, 1.6, "food", base=1.05)
    c.px(3, 1, "#5d7a2c")
    return c.render()


def wrapper():
    c = Canvas(7, 7, PROP_MATS)
    c.ellipse(3.5, 3.5, 2.5, 2.3, "paper", base=1.05)
    c.px(2, 3, "#8d877d")
    c.px(4, 4, "#a39c91")
    return c.render()


BIN_W, BIN_H = 22, 34


def bin_parts():
    """Back = the dark opening (drawn behind props); front = body + front lip."""
    back = Canvas(BIN_W, BIN_H, PROP_MATS)
    back.ellipse(11, 5, 8.5, 2.6, "bin", base=0.05, flat=True)
    front = Canvas(BIN_W, BIN_H, PROP_MATS)
    front.poly([(2.5, 5), (19.5, 5), (18.5, 32), (3.5, 32)], "bin", base=0.95, peak=0.3)
    for y in range(9, 13):
        for x in range(3, 20):
            front.shade_px(x, y, "gold", 0.9 - 0.06 * abs(x - 8))
    for x in range(3, 20):
        front.shade_px(x, 6, "bin", 0.9)
        front.shade_px(x, 7, "bin", 0.6)
    for x in range(6, 17, 3):
        front.shade_px(x, 10, "gold", 0.1)
    return back.render(outline=False), front.render()


def build():
    images = {
        "far.png": far_layer(),
        "market.png": market_layer(),
        "fore.png": fore_layer(),
        "glow.png": glow(),
        "crumb.png": crumb(),
        "wrapper.png": wrapper(),
    }
    b, f = bin_parts()
    images["bin_back.png"] = b
    images["bin_front.png"] = f
    for kind in WALKERS:
        for i in range(4):
            images["%s_%d.png" % (kind, i)] = walker_frame(kind, i)
    for i in range(3):
        images["vendor_%d.png" % i] = vendor_frame(i)
    return images
