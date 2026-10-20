#!/usr/bin/env python3
"""Builds App Store marketing screenshots (1320x2868, iPhone 6.9") from REAL simulator
screenshots captured by CI (ScreenshotTests) and the app's own share-card render.

usage: make_store_screenshots.py <dir with CI png files> <output dir>
Nothing here fabricates UI: every phone screen is an unedited simulator capture.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC, OUT = sys.argv[1], sys.argv[2]
W, H = 1320, 2868
BG, RED, WHITE, GRAY = (11, 11, 13), (255, 51, 71), (247, 247, 248), (150, 150, 159)
FONT = "/usr/share/fonts/opentype/inter/Inter-{}.otf"

def font(weight, size): return ImageFont.truetype(FONT.format(weight), size)

def pick(*names):
    for n in names:
        p = os.path.join(SRC, n + ".png")
        if os.path.exists(p): return Image.open(p).convert("RGB")
    raise SystemExit(f"missing screenshot: {names}")

def canvas(glow_y=0.62, glow=(120, 10, 28)):
    img = Image.new("RGB", (W, H), BG)
    g = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(g)
    cx, cy, r = W // 2, int(H * glow_y), 760
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=glow)
    g = g.filter(ImageFilter.GaussianBlur(260))
    return Image.blend(img, g, 0.85)

def headline(img, lines, sub, top=190):
    d = ImageDraw.Draw(img)
    y = top
    f = font("ExtraBold", 168)
    for segs in lines:
        total = sum(d.textlength(t, font=f) for t, _ in segs)
        x = (W - total) / 2
        for t, col in segs:
            d.text((x, y), t, font=f, fill=col)
            x += d.textlength(t, font=f)
        y += 178
    f2 = font("Medium", 56)
    # wrap sub to two lines max
    words, line, rows = sub.split(), "", []
    for w in words:
        t = (line + " " + w).strip()
        if d.textlength(t, font=f2) > W - 220 and line:
            rows.append(line); line = w
        else: line = t
    rows.append(line)
    y += 34
    for row in rows:
        d.text(((W - d.textlength(row, font=f2)) / 2, y), row, font=f2, fill=GRAY)
        y += 78
    return y

def rounded(im, radius):
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0] - 1, im.size[1] - 1], radius, fill=255)
    out = im.convert("RGBA"); out.putalpha(m); return out

def phone(img, shot, top, width=1020):
    scale = width / shot.width
    s = shot.resize((width, int(shot.height * scale)), Image.LANCZOS)
    r = int(width * 0.115)
    pad = 20
    x = (W - width) // 2
    # shadow
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x - pad, top - pad + 30, x + width + pad, top + s.height + pad + 30], r + pad, fill=(0, 0, 0, 200))
    img.paste(Image.alpha_composite(img.convert("RGBA"), sh.filter(ImageFilter.GaussianBlur(40))).convert("RGB"))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([x - pad, top - pad, x + width + pad, top + s.height + pad], r + pad, fill=(22, 22, 26), outline=(58, 58, 66), width=3)
    img.paste(rounded(s, r), (x, top), rounded(s, r))
    # dynamic island
    iw, ih = int(width * 0.215), int(width * 0.062)
    d.rounded_rectangle([W // 2 - iw // 2, top + int(width * 0.03), W // 2 + iw // 2, top + int(width * 0.03) + ih], ih // 2, fill=(0, 0, 0))

def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.crop((0, 0, W, H)).save(os.path.join(OUT, name), optimize=True)
    print("wrote", name)

def slide_phone(name, lines, sub, shot, top=None):
    img = canvas()
    y = headline(img, lines, sub)
    phone(img, shot, top if top is not None else y + 70)
    save(img, name)

R = lambda t: (t, RED)
Wt = lambda t: (t, WHITE)

slide_phone("01-dont.png", [[Wt("Whatever you do,")], [R("don't.")]],
            "One button. One rule. Zero self-control.", pick("01-launch"))
slide_phone("02-opinions.png", [[Wt("It has")], [R("opinions.")]],
            "100+ hand-written reactions, judging every single press.", pick("02-run-12"))
slide_phone("03-milestones.png", [[Wt("Level up your")], [R("bad decisions.")]],
            "Milestones at 10, 25, 50, 100 and beyond.", pick("03-milestone-25"))
slide_phone("04-worse.png", [[Wt("It only gets")], [R("worse.")]],
            "Keep going. The reactions get stranger.", pick("03d-run-110", "03c-run-75", "03b-run-40"))

# 05: the app's own rendered share card
img = canvas(glow_y=0.6)
y = headline(img, [[Wt("Share your")], [R("shame.")]], "A clean achievement card, one tap away.")
card = pick("07-share-card-847")
cw = 1000
c = card.resize((cw, int(card.height * cw / card.width)), Image.LANCZOS)
sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
cx = (W - cw) // 2; cy = y + 90
ImageDraw.Draw(sh).rounded_rectangle([cx, cy + 40, cx + cw, cy + c.height + 40], 56, fill=(0, 0, 0, 210))
img = Image.alpha_composite(img.convert("RGBA"), sh.filter(ImageFilter.GaussianBlur(50))).convert("RGB")
img.paste(rounded(c, 56), (cx, cy), rounded(c, 56))
ImageDraw.Draw(img).rounded_rectangle([cx, cy, cx + cw, cy + c.height], 56, outline=(58, 58, 66), width=3)
save(img, "05-share.png")

slide_phone("06-private.png", [[Wt("No ads. No accounts.")], [R("No excuses.")]],
            "Works offline. Nothing leaves your phone.", pick("03b-run-40", "02-run-12"))
