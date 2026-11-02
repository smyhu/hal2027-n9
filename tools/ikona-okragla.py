# Round launcher icon (80x80, transparent outside the eye) from the eye layers:
# ring, red glow, core and reflections, cut to a circle and scaled to 78 px.
from PIL import Image, ImageDraw
base = Image.new('RGBA', (440, 440), (0, 0, 0, 0))
for n in ['pierscien.png', 'poswiata-red.png', 'rdzen-red.png', 'odblaski.png']:
    base = Image.alpha_composite(base, Image.open(n).convert('RGBA').resize((440, 440)))
S = 4
mask = Image.new('L', (440 * S, 440 * S), 0)
ImageDraw.Draw(mask).ellipse((1.5 * S, 1.5 * S, 440 * S - 1.5 * S, 440 * S - 1.5 * S), fill=255)
base.putalpha(mask.resize((440, 440), Image.LANCZOS))
icon = Image.new('RGBA', (80, 80), (0, 0, 0, 0))
icon.alpha_composite(base.resize((78, 78), Image.LANCZOS), (1, 1))
icon.save('hal2027-80.png')
