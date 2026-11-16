from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
out=Path(__file__).parent
im=Image.new('RGB',(1400,1020),'#f8fafb');d=ImageDraw.Draw(im)
font='/System/Library/Fonts/Supplemental/Arial.ttf'
f=lambda n:ImageFont.truetype(font,n)
d.text((35,25),'Proposed space budgets — not implemented floor plans',font=f(29),fill='#172e39')
d.text((35,68),'Town units. Multiply lengths by 1.3 for world units. Both diagrams use the same scale.',font=f(18),fill='#415461')
scale=20

def rect(origin,x,y,w,h,color,label=''):
 ox,oy=origin; coords=(ox+x*scale,oy+y*scale,ox+(x+w)*scale,oy+(y+h)*scale)
 d.rectangle(coords,fill=color,outline='#526b76',width=2)
 if label:
  rows=label.split('\n'); text='\n'.join(rows)
  bbox=d.multiline_textbbox((0,0),text,font=f(16),spacing=4,align='center')
  d.multiline_text(((coords[0]+coords[2]-(bbox[2]-bbox[0]))/2,(coords[1]+coords[3]-(bbox[3]-bbox[1]))/2),text,font=f(16),spacing=4,align='center',fill='#172e39')
left=(65,190);right=(775,190)
d.text((65,125),'School: 24 × 18, one floor',font=f(24),fill='#172e39')
d.text((775,125),'Supermarket: 26 × 26',font=f(24),fill='#172e39')
rect(left,0,0,24,18,'#e5e6e4')
rect(left,.2,.2,23.6,17.6,'#fff6d9')
rect(left,.2,3.6,10,14.2,'#d8e9f0','General classroom\n10 × 14.2\n8 student places\n+ teacher / supplies')
rect(left,13.8,3.6,10,14.2,'#ddebdc','Science classroom\n10 × 14.2\n2 lab benches\n+ wall displays')
d.text((left[0]+10.5*scale,left[1]+7*scale),'3.2\nclear\nspine',font=f(15),fill='#614d25')
d.text((left[0]+6*scale,left[1]+.9*scale),'Entry / shared circulation',font=f(17),fill='#614d25')
d.line((left[0]+10.4*scale,left[1],left[0]+13.6*scale,left[1]),fill='#cc6a37',width=7)
rect(right,0,0,26,26,'#e5e6e4');rect(right,.25,.25,25.5,25.5,'#fff6d9')
width=(25.5-5.6)/3
labels=[['Checkout\n2 lanes','Produce + entry\n3.2 clear center','Beverages /\nhousehold'],['Dry foods /\nsnacks / cans','Refrigerated','Frozen'],['Seafood\ncounter','Meat\ncounter','Bakery /\nbread']]
ys=[.25,8.05,18.85];hs=[5,8,6.9]
for row in range(3):
 for col in range(3):rect(right,.25+col*(width+2.8),ys[row],width,hs[row],['#d8e9f0','#ddebdc','#e9dfec'][row],labels[row][col])
d.line((right[0]+11.4*scale,right[1],right[0]+14.6*scale,right[1]),fill='#cc6a37',width=7)
d.text((775,735),'Yellow bands: 2.8-wide continuous aisles',font=f(18),fill='#614d25')
d.text((65,590),'School assumptions',font=f(21),fill='#172e39')
d.multiline_text((65,627),'• Eight student desks; two practical lab benches\n• Room rectangles include furniture + local aisles\n• 3.2-wide entrance/spine; room doors still to design\n• Existing entrance stays at town (0, 221)\n• Remove upper floors / rear wing only in later work',font=f(17),spacing=12,fill='#415461')
d.multiline_text((775,780),'Departments are open zones, not enclosed rooms.\nEach zone includes displays, service and local circulation.\nThe plan allows compact representative assortments,\nnot full commercial inventory or a stockroom.',font=f(17),spacing=10,fill='#415461')
d.line((35,925,1365,925),fill='#b8c6cd',width=2)
d.text((35,945),'Player reference: collision diameter 1.17 town / 1.52 world; visual height ≈1.72 town / 2.24 world.',font=f(18),fill='#172e39')
im.save(out/'space-budgets.png')
print(out/'space-budgets.png')
