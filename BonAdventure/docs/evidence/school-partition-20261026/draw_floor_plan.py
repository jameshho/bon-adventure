from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# Current wall-only plan, in town units. Furniture is intentionally not drawn.
out = Path(__file__).parent
image = Image.new('RGB', (1000, 860), '#f8faf8')
d = ImageDraw.Draw(image)
font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
def font(size): return ImageFont.truetype(font_path, size)
def text(x, y, value, size=22, color='#293e40', anchor='mm'):
    d.text((x, y), value, font=font(size), fill=color, anchor=anchor)
scale=28
left, top=164, 168
right, bottom=left+24*scale, top+18*scale
center=(left+right)/2
mid=top+9*scale
text(500, 43, 'School — current interior floor plan', 30)
text(500, 83, '26 October 2026 · single story · 24 × 18 town units', 19)
d.rectangle((left,top,right,bottom), fill='#eee5d4')
d.rectangle((left+7,mid,right-7,bottom-7), fill='#e4efe8')
# Exterior boundaries and unchanged 3.6-wide centered entrance.
d.line([(left,bottom),(left,top),(right,top),(right,bottom)], fill='#496f78',width=7)
gap=3.6*scale/2
d.line((left,bottom,center-gap,bottom),fill='#496f78',width=7)
d.line((center+gap,bottom,right,bottom),fill='#496f78',width=7)
# The only interior wall: centerline, full height, rear half only.
d.line((center,top,center,mid),fill='#b98367',width=6)
text(500,135,'BACK / REAR EXTERIOR WALL',18)
text(320,260,'Left side',23)
text(680,260,'Right side',23)
text(640,340,'Single center wall',20)
text(640,372,'9 long · 0.2 thick · 4.6 high',17)
d.line((535,355,center+5,355),fill='#b98367',width=2)
text(500,485,'OPEN FRONT HALF',26)
text(500,520,'No interior walls or partitions',20)
d.line((left+90,565,right-90,565),fill='#52786b',width=3)
d.polygon([(left+90,565),(left+107,557),(left+107,573)],fill='#52786b')
d.polygon([(right-90,565),(right-107,557),(right-107,573)],fill='#52786b')
text(500,600,'Free left–right circulation',19)
text(500,707,'FRONT / EXISTING ENTRANCE',19)
# Dimension bars stay outside the shell; midpoint ticks are not interior walls.
for y0,y1,label in [(top,mid,'9'),(mid,bottom,'9')]:
    d.line((110,y0,110,y1),fill='#647779',width=2)
    for y in [y0,y1]: d.line((103,y,117,y),fill='#647779',width=2)
    text(82,(y0+y1)/2,label,22)
text(500,771,'Exterior walls, footprint, furnishings and entrance remain in place.',18)
text(500,805,'Wall-only schematic; see the rendered cutaway for retained furniture.',17)
image.save(out/'floor-plan.png')
