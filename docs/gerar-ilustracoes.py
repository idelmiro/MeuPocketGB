#!/usr/bin/env python3
"""Draws the PocketGo (v1, held sideways) as a vector image with a real screen
capture inside, for the README: docs/pocketgo-<name>.svg for each docs/telas/<name>.png.

The screen captures come from the emulator itself (PC test build, -DMPGB_TEST,
MPGB_CAPTURAS) and are embedded in the SVG, so GitHub shows them inside <img>.
The maker's logo printed under the screen is left out on purpose.

Usage: python3 docs/gerar-ilustracoes.py   (from the repository root)
"""
import base64
import glob
import os

HERE = os.path.dirname(os.path.abspath(__file__))

BODY = '#ECE9E2'
BODY_EDGE = '#D3CFC6'
GRIP = '#6B6B70'
BEZEL = '#5C5B6A'
DPAD = '#626266'
DPAD_EDGE = '#4A4A4F'
BLACK_BTN = '#1E1E22'
PURPLE_BTN = '#962A78'
LABEL = '#3A3F86'
SMALL_LABEL = '#A19D95'

TEMPLATE = '''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="80 52 850 410" width="850" height="410" role="img" aria-label="{alt}">
  <title>{alt}</title>
  <defs>
    <linearGradient id="corpo" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#F4F2EC"/>
      <stop offset="1" stop-color="{body}"/>
    </linearGradient>
    <radialGradient id="roxo" cx="0.4" cy="0.35" r="0.7">
      <stop offset="0" stop-color="#C04A9F"/>
      <stop offset="1" stop-color="{purple}"/>
    </radialGradient>
    <radialGradient id="preto" cx="0.4" cy="0.35" r="0.7">
      <stop offset="0" stop-color="#46464D"/>
      <stop offset="1" stop-color="{black}"/>
    </radialGradient>
    <filter id="sombra" x="-10%" y="-10%" width="120%" height="130%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="7"/>
      <feOffset dy="6" result="s"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.28"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <filter id="botao" x="-30%" y="-30%" width="160%" height="170%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="1.5"/>
      <feOffset dy="2"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.35"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <!-- shoulder grips (L / R) behind the body -->
  <rect x="104" y="66" width="120" height="40" rx="14" fill="{grip}"/>
  <rect x="786" y="66" width="120" height="40" rx="14" fill="{grip}"/>

  <!-- body -->
  <rect x="95" y="76" width="820" height="370" rx="62" fill="url(#corpo)" stroke="{body_edge}" stroke-width="2" filter="url(#sombra)"/>

  <!-- screen: bezel, real capture (320x240), power LED -->
  <rect x="300" y="100" width="415" height="308" rx="18" fill="{bezel}"/>
  <rect x="300" y="100" width="415" height="308" rx="18" fill="none" stroke="#45444F" stroke-width="2"/>
  <rect x="343" y="121" width="334" height="252" rx="3" fill="#000"/>
  <image x="345" y="123" width="330" height="247.5" preserveAspectRatio="none" style="image-rendering:pixelated" xlink:href="data:image/png;base64,{png}" href="data:image/png;base64,{png}"/>
  <circle cx="702" cy="140" r="3.2" fill="#72E04E"/>

  <!-- d-pad -->
  <g filter="url(#botao)">
    <rect x="115" y="195" width="150" height="56" rx="9" fill="{dpad}" stroke="{dpad_edge}" stroke-width="2"/>
    <rect x="162" y="148" width="56" height="150" rx="9" fill="{dpad}" stroke="{dpad_edge}" stroke-width="2"/>
    <rect x="164" y="197" width="52" height="52" fill="{dpad}"/>
  </g>
  <circle cx="190" cy="223" r="11" fill="#58585C"/>

  <!-- select / start -->
  <text x="226" y="344" font-family="Nunito, Arial, sans-serif" font-size="13" letter-spacing="1" fill="{small_label}" text-anchor="end">SELECT</text>
  <text x="226" y="396" font-family="Nunito, Arial, sans-serif" font-size="13" letter-spacing="1" fill="{small_label}" text-anchor="end">START</text>
  <circle cx="256" cy="339" r="18" fill="{dpad}" stroke="{dpad_edge}" stroke-width="2" filter="url(#botao)"/>
  <circle cx="256" cy="391" r="18" fill="{dpad}" stroke="{dpad_edge}" stroke-width="2" filter="url(#botao)"/>

  <!-- face buttons: X top, Y left, A right, B bottom -->
  <g filter="url(#botao)">
    <circle cx="818" cy="161" r="27" fill="url(#preto)"/>
    <circle cx="764" cy="215" r="27" fill="url(#preto)"/>
    <circle cx="871" cy="215" r="27" fill="url(#roxo)"/>
    <circle cx="818" cy="269" r="27" fill="url(#roxo)"/>
  </g>
  <g font-family="Nunito, Arial, sans-serif" font-size="15" font-weight="700" fill="{label}" text-anchor="middle">
    <text x="818" y="211">X</text>
    <text x="764" y="265">Y</text>
    <text x="871" y="265">A</text>
    <text x="818" y="318">B</text>
  </g>

  <!-- speaker -->
  <g stroke-linecap="round">
{speaker}
  </g>
</svg>
'''


def speaker():
    out = []
    for i in range(5):
        x = 760 + i * 20
        top, bottom = 352 - i * 6, 392 - i * 2
        out.append('    <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#BDB9B0" stroke-width="9"/>' % (x, bottom, x + 10, top))
        out.append('    <line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#8E8A83" stroke-width="4"/>' % (x, bottom, x + 10, top))
    return '\n'.join(out)


ALT = {
    'boot': 'PocketGo ligando com o MeuPocketGB: tela de boot com barra de progresso',
    'lista': 'PocketGo com o MeuPocketGB: lista de jogos',
    'menu-do-jogo': 'PocketGo com o MeuPocketGB: menu do jogo com Salvar e a miniatura do estado salvo',
    'opcoes': 'PocketGo com o MeuPocketGB: tela de Opções',
}


def main():
    for png in sorted(glob.glob(os.path.join(HERE, 'telas', '*.png'))):
        name = os.path.splitext(os.path.basename(png))[0]
        data = base64.b64encode(open(png, 'rb').read()).decode()
        svg = TEMPLATE.format(alt=ALT.get(name, 'PocketGo com o MeuPocketGB'), png=data, speaker=speaker(),
                              body=BODY, body_edge=BODY_EDGE, grip=GRIP, bezel=BEZEL, dpad=DPAD,
                              dpad_edge=DPAD_EDGE, black=BLACK_BTN, purple=PURPLE_BTN, label=LABEL,
                              small_label=SMALL_LABEL)
        out = os.path.join(HERE, 'pocketgo-%s.svg' % name)
        open(out, 'w').write(svg)
        print(out, len(svg) // 1024, 'KB')


if __name__ == '__main__':
    main()
