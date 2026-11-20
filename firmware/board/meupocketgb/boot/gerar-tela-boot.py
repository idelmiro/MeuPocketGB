#!/usr/bin/env python3
"""Draws the MeuPocketGB boot screen (console name + progress bar, same look as
the menus: Nunito font, black background, white text, pill-shaped bar).

Usage: gerar-tela-boot.py "emulador/ui/Nunito[wght].ttf" firmware/board/meupocketgb
Writes (all 320x240, the same picture):
  boot/tela-boot.bmp                          u-boot splash (8-bit BMP: u-boot's CFB
                                              only draws 4/8/24-bit), bar at 0 %
  rootfs/usr/share/meupocketgb/tela-boot.rgb565   whole frame for /dev/fb0
  rootfs/usr/share/meupocketgb/barra-NNN.rgb565   just the bar rows, per percent
/etc/main writes the frame once the kernel turns the screen on, then one bar
strip per boot step (dd ... bs=STRIP seek=BAR_Y/BAR_H): no text console used.
Needs Pillow; run again only when the drawing changes.
"""
import os
import struct
import sys
from PIL import Image, ImageDraw, ImageFont

TTF, BOARD = sys.argv[1], sys.argv[2]
W, H, SS = 320, 240, 4
NAME = 'PocketGo'
BAR_X, BAR_Y, BAR_W, BAR_H = 110, 150, 100, 6       # BAR_Y is a multiple of BAR_H (dd seek)
PERCENTS = (0, 10, 25, 30, 40, 50, 80, 100)        # values used by /etc/main
GRAY = (40, 40, 40)


def frame(pct):
    im = Image.new('RGB', (W * SS, H * SS), (0, 0, 0))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(TTF, 30 * SS)
    f.set_variation_by_name('Black')
    d.text((W / 2 * SS, 104 * SS), NAME, font=f, fill=(255, 255, 255), anchor='mm')
    r = BAR_H * SS // 2
    d.rounded_rectangle([BAR_X * SS, BAR_Y * SS, (BAR_X + BAR_W) * SS - 1, (BAR_Y + BAR_H) * SS - 1], radius=r, fill=GRAY)
    if pct:
        w = max(BAR_H, BAR_W * pct // 100)
        d.rounded_rectangle([BAR_X * SS, BAR_Y * SS, (BAR_X + w) * SS - 1, (BAR_Y + BAR_H) * SS - 1], radius=r,
                            fill=(255, 255, 255))
    return im.resize((W, H), Image.LANCZOS)


def rgb565(im, y0=0, y1=H):
    out = bytearray()
    px = im.load()
    for y in range(y0, y1):
        for x in range(W):
            r, g, b = px[x, y]
            out += struct.pack('<H', ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3))
    return bytes(out)


def bmp8(im, path):  # grey levels only (white / grey / black): 8-bit grey palette
    grey = im.convert('L')
    pal = b''.join(struct.pack('<BBBB', i, i, i, 0) for i in range(256))
    rows = b''.join(grey.tobytes()[y * W:(y + 1) * W] for y in reversed(range(H)))
    off = 14 + 40 + len(pal)
    hdr = b'BM' + struct.pack('<IHHI', off + len(rows), 0, 0, off)
    dib = struct.pack('<IiiHHIIiiII', 40, W, H, 1, 8, 0, len(rows), 2835, 2835, 256, 0)
    open(path, 'wb').write(hdr + dib + pal + rows)


def main():
    share = os.path.join(BOARD, 'rootfs/usr/share/meupocketgb')
    os.makedirs(share, exist_ok=True)
    first = frame(0)
    bmp8(first, os.path.join(BOARD, 'boot/tela-boot.bmp'))
    open(os.path.join(share, 'tela-boot.rgb565'), 'wb').write(rgb565(first))
    for pct in PERCENTS:
        strip = rgb565(frame(pct), BAR_Y, BAR_Y + BAR_H)
        open(os.path.join(share, 'barra-%03d.rgb565' % pct), 'wb').write(strip)


if __name__ == '__main__':
    main()
