"""Composite Archie poses side by side for visual review: preview_rig.py <out.png>"""
import sys

from PIL import Image

import rig_archie as rig
from raster import upscale

POSES = [
    dict(arm_l="eat", arm_r="phone_up", eyes="down", brows="normal", mouth="chew_a"),
    dict(arm_l="hold", arm_r="phone_low", eyes="open", brows="normal", mouth="closed"),
    dict(arm_l="hold", arm_r="phone_low", eyes="wide", brows="up", mouth="agape"),
    dict(arm_l="wave_b", arm_r="phone_up", eyes="down", brows="normal", mouth="talk_b"),
    dict(arm_l="throw_back", arm_r="phone_up", eyes="down", brows="quirk", mouth="smirk"),
    dict(arm_l="throw_release", arm_r="rest", eyes="open", brows="knit", mouth="talk_a"),
]


def compose(imgs, pose):
    out = Image.new("RGBA", (rig.W, rig.H), (0, 0, 0, 0))
    for key in ["shadow.png", "legs.png", "torso.png", "head.png", "eyes_%s.png" % pose["eyes"],
                "brows_%s.png" % pose["brows"], "mouth_%s.png" % pose["mouth"],
                "arm_r_%s.png" % pose["arm_r"], "arm_l_%s.png" % pose["arm_l"]]:
        out.alpha_composite(imgs[key])
    return out


def main():
    imgs = rig.build()
    sheet = Image.new("RGBA", (rig.W * len(POSES), rig.H), (196, 170, 140, 255))
    for i, pose in enumerate(POSES):
        sheet.alpha_composite(compose(imgs, pose), (i * rig.W, 0))
    upscale(sheet, 3).save(sys.argv[1])
    face = Image.new("RGBA", (40 * len(POSES), 46), (196, 170, 140, 255))
    for i, pose in enumerate(POSES):
        face.alpha_composite(compose(imgs, pose).crop((28, 0, 68, 46)), (i * 40, 0))
    upscale(face, 8).save(sys.argv[1].replace(".png", "_face.png"))


if __name__ == "__main__":
    main()
