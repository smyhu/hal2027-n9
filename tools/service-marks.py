# Service icons for the conversation list: white mark on transparent, 80x80.
# Source: @lobehub/icons-static-svg (MIT), monochrome variants.
import io, re, sys, cairosvg
from PIL import Image
SRC = 'lobe/package/icons/'  # unpacked @lobehub/icons-static-svg
OUT = 'service-marks/'
ICONS = {'gemini': 'gemini', 'claude': 'claude', 'claude-anthropic': 'anthropic', 'openai': 'openai',
         'openrouter': 'openrouter', 'groq': 'groq', 'mistral': 'mistral', 'xai': 'xai'}
for name, src in ICONS.items():
    svg = open(SRC + src + '.svg').read()
    svg = svg.replace('currentColor', '#ffffff')
    svg = re.sub(r'fill="(?!none)[^"]*"', 'fill="#ffffff"', svg)
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=448, output_height=448)
    mark = Image.open(io.BytesIO(png)).convert('RGBA').resize((56, 56), Image.LANCZOS)
    im = Image.new('RGBA', (80, 80), (0, 0, 0, 0))
    im.paste(mark, (12, 12), mark)
    im.save(OUT + 'service-%s.png' % name)
    print(name)
