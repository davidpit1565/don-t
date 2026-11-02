#!/usr/bin/env python3
"""Builds App Store marketing screenshots (1320x2868, iPhone 6.9") from REAL simulator
screenshots captured by CI (ScreenshotTests) and the app's own share-card render.

usage: make_store_screenshots.py <dir with CI png files> <output dir> [--set v10|v11]

  --set v10 (default)  the 1.0 slide set (8 slides).
  --set v11            the 1.1 slide set (10 slides): set-pieces, egg, balloon, daily challenge,
                       Reactiondex and the v2 share card, from the `v11-*` captures in
                       DontPressUITests/ScreenshotTests.swift. A slide whose capture (and its
                       same-feature fallback) is missing is skipped with a warning, never faked.

Nothing here fabricates UI: every phone screen is an unedited simulator capture.
"""
import argparse, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC = OUT = None   # set in main()
W, H = 1320, 2868
BG, RED, WHITE, GRAY = (11, 11, 13), (255, 51, 71), (247, 247, 248), (150, 150, 159)
FONT = "/usr/share/fonts/opentype/inter/Inter-{}.otf"

def font(weight, size): return ImageFont.truetype(FONT.format(weight), size)

def find(*names):
    """First existing capture among `names` (in order), or None."""
    for n in names:
        p = os.path.join(SRC, n + ".png")
        if os.path.exists(p): return Image.open(p).convert("RGB")
    return None

def pick(*names):
    img = find(*names)
    if img is None: raise SystemExit(f"missing screenshot: {names}")
    return img

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
    # one font size per slide, shrunk just enough that the widest line fits the margins
    size = 168
    widest = max(sum(d.textlength(t, font=font("ExtraBold", size)) for t, _ in segs) for segs in lines)
    if widest > W - 150:
        size = int(size * (W - 150) / widest)
    f = font("ExtraBold", size)
    for segs in lines:
        total = sum(d.textlength(t, font=f) for t, _ in segs)
        x = (W - total) / 2
        for t, col in segs:
            d.text((x, y), t, font=f, fill=col)
            x += d.textlength(t, font=f)
        y += int(size * 1.06)
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

def slide_card(name, lines, sub, card):
    """The app's own rendered share card (a real ImageRenderer output), centred under the headline."""
    img = canvas(glow_y=0.6)
    y = headline(img, lines, sub)
    cw = 1130
    c = card.resize((cw, int(card.height * cw / card.width)), Image.LANCZOS)
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    cx = (W - cw) // 2; cy = y + max(60, (H - y - c.height) // 2)
    ImageDraw.Draw(sh).rounded_rectangle([cx, cy + 40, cx + cw, cy + c.height + 40], 56, fill=(0, 0, 0, 210))
    img = Image.alpha_composite(img.convert("RGBA"), sh.filter(ImageFilter.GaussianBlur(50))).convert("RGB")
    img.paste(rounded(c, 56), (cx, cy), rounded(c, 56))
    ImageDraw.Draw(img).rounded_rectangle([cx, cy, cx + cw, cy + c.height], 56, outline=(58, 58, 66), width=3)
    save(img, name)

R = lambda t: (t, RED)
Wt = lambda t: (t, WHITE)

def build_v10():
    """The 1.0 set, unchanged."""
    slide_phone("01-dont.png", [[Wt("Whatever you do,")], [R("don't.")]],
                "One button. One rule. Zero self-control.", pick("01-launch"))
    slide_phone("02-opinions.png", [[Wt("It has")], [R("opinions.")]],
                "100+ hand-written reactions, judging every single press.", pick("02-run-12"))
    slide_phone("03-levelup.png", [[Wt("Level up your")], [R("bad decisions.")]],
                "Milestones and achievements unlock as you go.", pick("02a-unlock-10", "03-milestone-25"))
    slide_phone("04-worse.png", [[Wt("It only gets")], [R("worse.")]],
                "Keep going. The reactions get stranger.", pick("03d-run-110", "03c-run-75", "03b-run-40"))
    slide_phone("05-collect.png", [[Wt("Collect your")], [R("regrets.")]],
                "12 achievements. 5 button styles.", pick("09-collection"))
    slide_phone("06-style.png", [[Wt("Make it")], [R("yours.")]],
                "Unlock new button styles as you press.", pick("10-theme-gold"))

    # 07: the app's own rendered share card
    slide_card("07-share.png", [[Wt("Share your")], [R("shame.")]],
               "A clean achievement card, one tap away.", pick("07-share-card-847"))

    slide_phone("08-private.png", [[Wt("No ads. No accounts.")], [R("No excuses.")]],
                "Works offline. No data collected.", pick("03b-run-40", "02-run-12"))

def build_v11():
    """The 1.1 set. Headlines describe features that ship in 1.1; every screen is a real capture.
    Fallbacks only ever show the same feature (e.g. the 50 set-piece for the 25 one)."""
    slides = [
        ("01-dont.png", [[Wt("Whatever you do,")], [R("don't.")]],
         "One button. One rule. Zero self-control.", ("01-launch",)),
        ("02-fights-back.png", [[Wt("The button")], [R("fights back.")]],
         "Push it far enough and the button makes a scene.",
         ("v11-setpiece-25", "v11-setpiece-50-lock")),
        ("03-crack.png", [[R("Crack it.")]],
         "Tap the egg until something hatches. (Pro)", ("v11-egg-hatch", "v11-egg-crack")),
        ("04-pop.png", [[Wt("Every tap")], [R("inflates it.")]],
         "When it pops is a secret. (Pro)", ("v11-balloon", "v11-balloon-pop")),
        ("05-pinata.png", [[Wt("Whack it.")], [R("See what falls.")]],
         "The mythic Piñata. Pro, plus 5,000 total presses.", ("v11-pinata-burst", "v11-pinata")),
        ("06-daily.png", [[Wt("One challenge")], [R("a day.")]],
         "Same challenge for everyone. Keep your streak.", ("v11-daily",)),
        ("07-reactiondex.png", [[Wt("Collect every")], [R("reaction.")]],
         "Every line you find lands in the Reactiondex.", ("v11-reactiondex",)),
        ("09-pro.png", [[Wt("Pro. Once.")], [R("No subscription.")]],
         "Toys, styles and icons. The offer shows the price first.", ("12-pro-offer",)),
    ]
    for name, lines, sub, shots in slides:
        shot = find(*shots)
        if shot is None:
            print(f"skipped {name}: none of {shots} found", file=sys.stderr)
            continue
        slide_phone(name, lines, sub, shot)

    # 07: the v2 share card exactly as ShareImageRenderer draws it (ShareCardRenderTests).
    card = find("07-share-card-847", "09-share-card-v2-full")
    if card is None:
        print("skipped 08-share.png: no share-card render found", file=sys.stderr)
    else:
        slide_card("08-share.png", [[Wt("Share your")], [R("shame.")]],
                   "A card with your real personal best.", card)

    last = find("v11-collection", "09-collection", "03b-run-40", "01-launch")
    if last is None:
        print("skipped 10-private.png: no capture found", file=sys.stderr)
    else:
        slide_phone("10-private.png", [[Wt("No ads. No accounts.")], [R("No excuses.")]],
                    "Works offline. No data collected.", last)

def main():
    global SRC, OUT
    ap = argparse.ArgumentParser(description="Build App Store marketing screenshots from real captures.")
    ap.add_argument("src", help="directory with the CI PNG captures (named by XCTAttachment name)")
    ap.add_argument("out", help="output directory")
    ap.add_argument("--set", dest="set", choices=["v10", "v11"], default="v10", help="slide set (default: v10)")
    args = ap.parse_args()
    SRC, OUT = args.src, args.out
    {"v10": build_v10, "v11": build_v11}[args.set]()

if __name__ == "__main__":
    main()
