"""Tiny pixel-art rasteriser for stage assets.

Shapes are drawn as (material, shade) pairs, then resolved to palette ramps
and outlined, so every part of a rig shares one lighting model and one
palette. Shade 0.0 = darkest ramp entry, 1.0 = brightest.
"""
import math

from PIL import Image

# Key light from upper-left-front (normalised below).
LIGHT = (-0.55, -0.5, 0.67)
_L = math.sqrt(sum(c * c for c in LIGHT))
LIGHT = tuple(c / _L for c in LIGHT)

BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


class Material:
    def __init__(self, ramp, outline=None, dither=0.0, edge_against=()):
        self.ramp = [hexc(c) if isinstance(c, str) else c for c in ramp]
        self.outline = hexc(outline) if isinstance(outline, str) else (outline or self.ramp[0])
        self.dither = dither
        self.edge_against = set(edge_against)


class Canvas:
    def __init__(self, w, h, materials):
        self.w, self.h = w, h
        self.materials = materials
        self.mat = [[None] * w for _ in range(h)]
        self.val = [[0.0] * w for _ in range(h)]
        self.fixed = [[None] * w for _ in range(h)]

    # ── primitives ──────────────────────────────────────────────────
    def _put(self, x, y, mat, v):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.mat[y][x] = mat
            self.val[y][x] = v
            self.fixed[y][x] = None

    def clear(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.mat[y][x] = None
            self.fixed[y][x] = None

    def px(self, x, y, color):
        """Explicit colour (hex or rgba); kept through shading and outlining."""
        if 0 <= x < self.w and 0 <= y < self.h:
            c = hexc(color) if isinstance(color, str) else color
            self.fixed[y][x] = c
            if self.mat[y][x] is None:
                self.mat[y][x] = "_fixed"

    def shade_px(self, x, y, mat, v):
        self._put(x, y, mat, v)

    def poly(self, pts, mat, base=0.7, cyl=True, peak=0.3, vgrad=0.0, clip=None):
        """Scanline fill. cyl=True shades each row like a cylinder lit from the left."""
        ys = [p[1] for p in pts]
        y0, y1 = int(math.floor(min(ys))), int(math.ceil(max(ys)))
        n = len(pts)
        for y in range(y0, y1 + 1):
            yc = y + 0.5
            xs = []
            for i in range(n):
                ax, ay = pts[i]
                bx, by = pts[(i + 1) % n]
                if (ay <= yc < by) or (by <= yc < ay):
                    xs.append(ax + (yc - ay) * (bx - ax) / (by - ay))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                xa, xb = int(math.floor(xs[i] + 0.5)), int(math.floor(xs[i + 1] - 0.5))
                width = max(1, xb - xa)
                for x in range(xa, xb + 1):
                    if clip and not clip(x, y):
                        continue
                    v = base
                    if cyl:
                        t = (x - xa) / width
                        v = base * (1.08 - 1.15 * abs(t - peak) ** 1.25)
                    if vgrad:
                        v += vgrad * (y - y0) / max(1, y1 - y0)
                    self._put(x, y, mat, v)

    def rect(self, x0, y0, x1, y1, mat, v=0.6):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self._put(x, y, mat, v)

    def ellipse(self, cx, cy, rx, ry, mat, base=1.0, flat=False, clip=None):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                dx = (x + 0.5 - cx) / rx
                dy = (y + 0.5 - cy) / ry
                d = dx * dx + dy * dy
                if d <= 1.0:
                    if clip and not clip(x, y):
                        continue
                    if flat:
                        v = base
                    else:
                        nz = math.sqrt(max(0.0, 1.0 - d))
                        v = base * (0.35 + 0.8 * max(0.0, dx * LIGHT[0] + dy * LIGHT[1] + nz * LIGHT[2]))
                    self._put(x, y, mat, v)

    def capsule(self, p0, p1, r0, r1, mat, base=1.0, cap0=True, cap1=True):
        (ax, ay), (bx, by) = p0, p1
        dx, dy = bx - ax, by - ay
        ln2 = dx * dx + dy * dy or 1e-6
        ln = math.sqrt(ln2)
        px_, py_ = -dy / ln, dx / ln  # perpendicular
        r = max(r0, r1)
        for y in range(int(min(ay, by) - r - 1), int(max(ay, by) + r + 2)):
            for x in range(int(min(ax, bx) - r - 1), int(max(ax, bx) + r + 2)):
                qx, qy = x + 0.5 - ax, y + 0.5 - ay
                t = (qx * dx + qy * dy) / ln2
                if (t < 0 and not cap0) or (t > 1 and not cap1):
                    continue
                tc = min(1.0, max(0.0, t))
                rad = r0 + (r1 - r0) * tc
                cx, cy = ax + dx * tc, ay + dy * tc
                ox, oy = x + 0.5 - cx, y + 0.5 - cy
                dist = math.sqrt(ox * ox + oy * oy)
                if dist <= rad:
                    s = (ox * px_ + oy * py_) / rad
                    nx, ny = px_ * s, py_ * s
                    nz = math.sqrt(max(0.0, 1.0 - s * s))
                    v = base * (0.35 + 0.8 * max(0.0, nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]))
                    self._put(x, y, mat, v)

    def line(self, x0, y0, x1, y1, color):
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) or 1
        for i in range(steps + 1):
            t = i / steps
            self.px(int(round(x0 + (x1 - x0) * t)), int(round(y0 + (y1 - y0) * t)), color)

    def stamp(self, x0, y0, rows, key):
        """ASCII stamp: each char maps via key to a colour; space/'.' = skip."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in " .":
                    continue
                c = key[ch]
                if c is None:
                    self.clear(x0 + i, y0 + j)
                elif isinstance(c, tuple) and len(c) == 2 and isinstance(c[0], str) and c[0] in self.materials:
                    self.shade_px(x0 + i, y0 + j, c[0], c[1])
                else:
                    self.px(x0 + i, y0 + j, c)

    def mask(self):
        return [[self.mat[y][x] is not None for x in range(self.w)] for y in range(self.h)]

    # ── resolve ─────────────────────────────────────────────────────
    def render(self, outline=True, outline_skip=None):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        out = img.load()
        for y in range(self.h):
            for x in range(self.w):
                m = self.mat[y][x]
                if m is None:
                    continue
                if self.fixed[y][x] is not None:
                    out[x, y] = self.fixed[y][x]
                    continue
                mat = self.materials[m]
                n = len(mat.ramp)
                v = self.val[y][x]
                if mat.dither:
                    v += (BAYER4[y % 4][x % 4] / 15.0 - 0.5) * mat.dither
                idx = min(n - 1, max(0, int(v * n)))
                # Inner edge: darkest shade where this material meets a listed one.
                if mat.edge_against:
                    for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + ddx, y + ddy
                        if 0 <= nx < self.w and 0 <= ny < self.h and self.mat[ny][nx] in mat.edge_against:
                            idx = 0
                            break
                out[x, y] = mat.ramp[idx]
        if outline:
            src = [[self.mat[y][x] for x in range(self.w)] for y in range(self.h)]
            for y in range(self.h):
                for x in range(self.w):
                    if src[y][x] is not None:
                        continue
                    if outline_skip and outline_skip(x, y):
                        continue
                    best = None
                    for ddx, ddy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + ddx, y + ddy
                        if 0 <= nx < self.w and 0 <= ny < self.h and src[ny][nx] is not None:
                            m = src[ny][nx]
                            c = self.fixed[ny][nx] if m == "_fixed" else self.materials[m].outline
                            if m == "_fixed":
                                c = darken(c, 0.45)
                            if best is None or sum(c[:3]) < sum(best[:3]):
                                best = c
                    if best is not None:
                        out[x, y] = best
        return img


def darken(c, f):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), c[3] if len(c) > 3 else 255)


def lerp_c(a, b, t):
    a = hexc(a) if isinstance(a, str) else a
    b = hexc(b) if isinstance(b, str) else b
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(4))


def upscale(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
