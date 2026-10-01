#!/usr/bin/env python3
"""
Builds every logo and app-icon asset from the vector logo (design/brand/plengo-logo.pdf).

    pip install pymupdf && python3 design/brand/make_brand.py

The PDF holds: path 0 = the white "sticker" outline, paths 1-6 = the letters P l e n o g,
paths 7-22 = the tagline "Play .. Learn .. Go!". Letters are recoloured per variant so the app,
admin, web and stores all use the same artwork.
"""
import json
import pathlib

import pymupdf

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'design/brand/plengo-logo.pdf'

# Brand palette (sampled from the master artwork).
YELLOW = '#FFD62C'
PINK = '#E3A4E8'
RED = '#E54E4E'
GREEN = '#1FCD33'
BLUE = '#0080C6'
ORANGE = '#F99A2C'
INK = '#1B1B1B'
MONO_BLUE = '#4370B7'  # the two-colour wordmark
MONO_RED = '#EB5956'

LETTERS = {1: PINK, 2: YELLOW, 3: RED, 4: GREEN, 6: BLUE, 5: ORANGE}  # P l e n g o


def paths():
    page = pymupdf.open(SRC)[0]
    out = []
    for dr in page.get_drawings():
        d = []
        for item in dr['items']:
            kind = item[0]
            if kind == 'l':
                a, b = item[1], item[2]
                d.append(f'M{a.x:.2f} {a.y:.2f}L{b.x:.2f} {b.y:.2f}' if not d else f'L{b.x:.2f} {b.y:.2f}')
            elif kind == 'c':
                a, c1, c2, b = item[1:5]
                head = '' if d else f'M{a.x:.2f} {a.y:.2f}'
                d.append(f'{head}C{c1.x:.2f} {c1.y:.2f} {c2.x:.2f} {c2.y:.2f} {b.x:.2f} {b.y:.2f}')
            elif kind == 're':
                r = item[1]
                d.append(f'M{r.x0:.2f} {r.y0:.2f}H{r.x1:.2f}V{r.y1:.2f}H{r.x0:.2f}Z')
            elif kind == 'qu':
                q = item[1]
                d.append(f'M{q.ul.x:.2f} {q.ul.y:.2f}L{q.ur.x:.2f} {q.ur.y:.2f}L{q.lr.x:.2f} {q.lr.y:.2f}L{q.ll.x:.2f} {q.ll.y:.2f}Z')
        out.append({'d': ''.join(d) + ('Z' if dr.get('closePath') else ''), 'rect': dr['rect'], 'even_odd': dr.get('even_odd', False)})
    return out


PATHS = paths()
BOX = PATHS[0]['rect']  # the sticker bounds the whole logo


def path_tag(i, fill):
    rule = ' fill-rule="evenodd"' if PATHS[i]['even_odd'] else ''
    return f'<path d="{PATHS[i]["d"]}" fill="{fill}"{rule}/>'


def svg(body, box, size=None, background=None):
    x, y, w, h = box
    attrs = f'width="{size[0]}" height="{size[1]}" ' if size else ''
    bg = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{background}"/>' if background else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" {attrs}viewBox="{x:.2f} {y:.2f} {w:.2f} {h:.2f}">{bg}{body}</svg>'


def wordmark(variant):
    """color: master artwork (white sticker, colour letters, ink tagline) for yellow backgrounds;
    blue: two-colour wordmark for light backgrounds; white: for dark or photo backgrounds."""
    if variant == 'color':
        parts = [path_tag(0, '#FFFFFF')] + [path_tag(i, c) for i, c in LETTERS.items()] + [path_tag(i, INK) for i in range(7, 23)]
    elif variant == 'blue':
        parts = [path_tag(i, MONO_BLUE) for i in range(1, 7)] + [path_tag(i, MONO_RED) for i in range(7, 23)]
    else:
        parts = [path_tag(i, '#FFFFFF') for i in range(1, 23)]
    pad = 4
    box = (BOX.x0 - pad, BOX.y0 - pad, BOX.width + 2 * pad, BOX.height + 2 * pad)
    return svg(''.join(parts), box)


def icon(size, maskable=False, foreground_only=False):
    """App icon: the brand "P" in white-outlined blue on yellow. Maskable/adaptive icons keep the
    glyph inside the central safe zone."""
    p = PATHS[1]['rect']
    side = max(p.width, p.height)
    scale = 0.48 if (maskable or foreground_only) else 0.62
    view = side / scale
    cx, cy = (p.x0 + p.x1) / 2, (p.y0 + p.y1) / 2
    box = (cx - view / 2, cy - view / 2, view, view)
    stroke = f'<path d="{PATHS[1]["d"]}" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="{side * 0.16:.2f}" stroke-linejoin="round"/>'
    glyph = stroke + path_tag(1, BLUE)
    return svg(glyph, box, (size, size), None if foreground_only else YELLOW)


def png(svg_text, target, width=None):
    doc = pymupdf.open(stream=svg_text.encode(), filetype='svg')
    page = doc[0]
    zoom = (width / page.rect.width) if width else 1
    pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=True)
    target.parent.mkdir(parents=True, exist_ok=True)
    pix.save(target)


def main():
    brand = ROOT / 'apps/mobile/assets/brand'
    for v in ('color', 'blue', 'white'):
        text = wordmark(v)
        (brand / f'wordmark-{v}.svg').parent.mkdir(parents=True, exist_ok=True)
        (brand / f'wordmark-{v}.svg').write_text(text)
        png(text, brand / f'wordmark-{v}.png', 960)
    # Admin (Next.js serves app/icon.png as the favicon).
    admin = ROOT / 'apps/admin'
    (admin / 'public').mkdir(exist_ok=True)
    (admin / 'public/wordmark-blue.svg').write_text(wordmark('blue'))
    png(icon(256), admin / 'src/app/icon.png')
    # Web.
    web = ROOT / 'apps/mobile/web'
    png(icon(192), web / 'icons/Icon-192.png')
    png(icon(512), web / 'icons/Icon-512.png')
    png(icon(192, maskable=True), web / 'icons/Icon-maskable-192.png')
    png(icon(512, maskable=True), web / 'icons/Icon-maskable-512.png')
    png(icon(64), web / 'favicon.png')
    # Android legacy icons + adaptive icon foreground.
    res = ROOT / 'apps/mobile/android/app/src/main/res'
    for folder, px in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
        png(icon(px), res / f'mipmap-{folder}/ic_launcher.png')
        png(icon(px * 108 // 48, foreground_only=True), res / f'mipmap-{folder}/ic_launcher_foreground.png')
    # iOS (no transparency allowed: the icon has a solid background).
    iconset = ROOT / 'apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset'
    contents = json.loads((iconset / 'Contents.json').read_text())
    for image in contents['images']:
        if 'filename' not in image:
            continue
        points = float(image['size'].split('x')[0])
        scale = int(image['scale'].rstrip('x'))
        target = iconset / image['filename']
        doc = pymupdf.open(stream=icon(round(points * scale)).encode(), filetype='svg')
        doc[0].get_pixmap(alpha=False).save(target)
    print('brand assets written')


if __name__ == '__main__':
    main()
