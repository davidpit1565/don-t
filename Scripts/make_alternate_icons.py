#!/usr/bin/env python3
"""Generate the alternate app icons (one per unlockable button style).

Re-run from the repository root:  python3 Scripts/make_alternate_icons.py
Writes 1024x1024 RGB PNGs (no alpha) into DontPress/Assets.xcassets/AppIcon-<Name>.appiconset
plus a matching Contents.json. The primary AppIcon.appiconset (Classic Red) is not touched.
Pass --preview to also write the Classic variant to the scratch path given, for visual comparison.

Colours mirror DontPress/Core/ButtonTheme.swift (highlightHex / baseHex / darkHex).
Geometry matches the shipped primary icon: near-black background, housing ring with a thin
grey edge, a glossy round button with a darker depth band underneath, a lighter rim and a
soft elliptical specular highlight.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "DontPress", "Assets.xcassets")

THEMES = {
    # icon set name: (highlight, base, dark)
    "AppIcon-Cobalt": (0x7DB1FF, 0x2F6BFF, 0x1B3FB0),
    "AppIcon-Stealth": (0x9A9AA6, 0x55555F, 0x2C2C33),
    "AppIcon-Radioactive": (0xA6FF94, 0x2ED65A, 0x138A33),
    "AppIcon-Gold": (0xFFDB78, 0xF2A900, 0xB07400),
}
CLASSIC = (0xFF6877, 0xFF3347, 0xC71930)

SIZE = 1024
SS = 2  # supersampling factor
N = SIZE * SS
BG = np.array([11, 11, 13], dtype=np.float64)


def rgb(hex_value):
    return np.array([(hex_value >> 16) & 0xFF, (hex_value >> 8) & 0xFF, hex_value & 0xFF], dtype=np.float64)


def mix(a, b, t):
    t = np.clip(t, 0, 1)[..., None]
    return a * (1 - t) + b * t


def disc(cx, cy, r, yy, xx, feather=1.5):
    """Anti-aliased disc coverage in [0, 1] (coordinates in 1x units)."""
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    return np.clip((r - d) / feather + 0.5, 0, 1)


def over(canvas, colour, alpha):
    a = np.clip(alpha, 0, 1)[..., None]
    return canvas * (1 - a) + colour * a


def render(highlight_hex, base_hex, dark_hex):
    hi, base, dark = rgb(highlight_hex), rgb(base_hex), rgb(dark_hex)
    ys, xs = np.mgrid[0:N, 0:N].astype(np.float64)
    yy, xx = (ys + 0.5) / SS, (xs + 0.5) / SS  # 1x coordinates
    canvas = np.broadcast_to(BG, (N, N, 3)).copy()

    cx = 512.0
    # Housing: soft drop shadow, grey edge, then a dark vertical gradient fill.
    shadow = Image.fromarray((disc(cx, 518, 384, yy, xx) * 255).astype(np.uint8))
    shadow = np.asarray(shadow.filter(ImageFilter.GaussianBlur(24 * SS)), dtype=np.float64) / 255
    canvas = over(canvas, np.zeros(3), shadow * 0.55)
    canvas = over(canvas, np.array([60, 60, 70.0]), disc(cx, 512, 378, yy, xx))
    t = (yy - 138) / (886 - 138)
    housing = mix(np.array([38, 38, 45.0]), np.array([14, 14, 17.0]), t)
    canvas = over(canvas, housing, disc(cx, 512, 373, yy, xx))

    # Depth band: same disc shifted down, in a deepened dark tone.
    fy, fr = 499.0, 316.0
    canvas = over(canvas, np.array([0, 0, 0.0]),
                  np.asarray(Image.fromarray((disc(cx, fy + 44, fr + 4, yy, xx) * 255).astype(np.uint8))
                             .filter(ImageFilter.GaussianBlur(10 * SS)), dtype=np.float64) / 255 * 0.6)
    canvas = over(canvas, dark * 0.56, disc(cx, fy + 38, fr, yy, xx))

    # Rim: lighter band around the face, highlight at the top fading to dark at the bottom.
    t = (yy - (fy - fr)) / (2 * fr)
    rim = np.where((t < 0.5)[..., None], mix(hi, base, t / 0.5), mix(base, dark * 1.02, (t - 0.5) / 0.5))
    canvas = over(canvas, rim, disc(cx, fy, fr, yy, xx))

    # Face: base at the top, dark at the bottom, slightly brighter shoulder.
    ir = fr - 22
    t = (yy - (fy - ir)) / (2 * ir)
    face = np.where((t < 0.55)[..., None], mix(base * 1.0 + 4, base * 0.94, t / 0.55),
                    mix(base * 0.94, dark, (t - 0.55) / 0.45))
    canvas = over(canvas, np.clip(face, 0, 255), disc(cx, fy + 2, ir, yy, xx))

    # Specular highlight: soft ellipse in the upper half, fading downwards, clipped to the face.
    ex, ey, erx, ery = cx, 392.0, 262.0, 165.0
    e = ((xx - ex) / erx) ** 2 + ((yy - ey) / ery) ** 2
    spec = Image.fromarray((np.clip((1.0 - e) * 4, 0, 1) * 255).astype(np.uint8))
    spec = np.asarray(spec.filter(ImageFilter.GaussianBlur(16 * SS)), dtype=np.float64) / 255
    fade = np.clip(1.0 - (yy - 300) / 260, 0, 1) * 0.35 + 0.65
    spec *= fade * disc(cx, fy + 2, ir, yy, xx)
    canvas = over(canvas, mix(hi, np.array([255, 255, 255.0]), np.full((N, N), 0.45)), spec * 0.38)

    img = Image.fromarray(np.clip(canvas, 0, 255).round().astype(np.uint8), "RGB")
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def contents(filename):
    return {
        "images": [{"filename": filename, "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }


def main():
    if "--preview" in sys.argv:
        out = sys.argv[sys.argv.index("--preview") + 1]
        render(*CLASSIC).save(out)
        print("wrote", out)
    for name, colours in THEMES.items():
        folder = os.path.join(ASSETS, name + ".appiconset")
        os.makedirs(folder, exist_ok=True)
        filename = name + "-1024.png"
        img = render(*colours)
        assert img.mode == "RGB" and img.size == (SIZE, SIZE)
        img.save(os.path.join(folder, filename), optimize=True)
        with open(os.path.join(folder, "Contents.json"), "w") as f:
            json.dump(contents(filename), f, indent=2)
            f.write("\n")
        print("wrote", os.path.join(folder, filename))


if __name__ == "__main__":
    main()
