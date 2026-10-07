"""Static composite of the stage at a camera position: preview_set.py <out.png>"""
import sys

from PIL import Image

import rig_archie as rig
import set_spitalfields as st
from preview_rig import compose
from raster import upscale

VP_W, VP_H = 195, 262
ARCHIE_X = 230
CAM_X = 205
BIN_X = 72


def frame(si, ri, cam_x, pose):
    cam_left = max(0, min(st.WORLD_W - VP_W, cam_x - VP_W // 2))
    top = VP_H - st.WORLD_H
    out = Image.new("RGBA", (VP_W, VP_H), (0, 0, 0, 255))

    def blit(img, x, y):
        out.alpha_composite(img, (0, 0), (0, 0)) if False else out.paste(img, (int(x), int(y)), img)

    blit(si["far.png"], -round(cam_left * st.FAR_P), top)
    for i, (kind, wx) in enumerate([("walker_a", 120), ("walker_b", 190), ("walker_c", 60)]):
        blit(si["%s_%d.png" % (kind, i)], wx - round(cam_left * st.FAR_P) - st.WALK_W // 2, top + st.WALK_Y - st.WALK_H)
    blit(si["market.png"], -cam_left, top)
    blit(si["vendor_1.png"], st.VENDOR_POS[0] - cam_left, top + st.VENDOR_POS[1])
    blit(si["bin_back.png"], BIN_X - st.BIN_W // 2 - cam_left, top + st.FLOOR_Y + 2 - st.BIN_H)
    blit(si["bin_front.png"], BIN_X - st.BIN_W // 2 - cam_left, top + st.FLOOR_Y + 2 - st.BIN_H)
    blit(compose(ri, pose), ARCHIE_X - rig.ORIGIN[0] - cam_left, top + st.FLOOR_Y - rig.ORIGIN[1])
    blit(si["fore.png"], -round(cam_left * st.FORE_P), top)
    g = si["glow.png"]
    for (x, y) in st.light_positions():
        gx, gy = x - cam_left - g.width // 2, top + y - g.height // 2
        layer = Image.new("RGBA", out.size, (0, 0, 0, 0))
        layer.paste(g, (gx, gy))
        out = Image.alpha_composite(out, layer)
    return out


def main():
    si = st.build()
    ri = rig.build()
    pose = dict(arm_l="eat", arm_r="phone_up", eyes="down", brows="normal", mouth="chew_a")
    a = frame(si, ri, CAM_X, pose)
    b = frame(si, ri, 150, dict(pose, arm_l="throw_release"))
    sheet = Image.new("RGBA", (VP_W * 2 + 4, VP_H), (255, 255, 255, 255))
    sheet.paste(a, (0, 0))
    sheet.paste(b, (VP_W + 4, 0))
    upscale(sheet, 3).save(sys.argv[1])


if __name__ == "__main__":
    main()
