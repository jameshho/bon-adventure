from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import math,shutil
p=Path(__file__).resolve().parents[1]
f=p/'assets/maps/town_map.png'
S=2; im=Image.new('RGB',(1500*S,1700*S),'#c1d9d6');d=ImageDraw.Draw(im)
font='/System/Library/Fonts/Supplemental/Arial.ttf'
def text(x,y,s,size=22,fill='#35544b',anchor='mm'):
 d.multiline_text((x*S,y*S),s,font=ImageFont.truetype(font,size*S),fill=fill,anchor=anchor,align='center',spacing=3*S)
def xy(p):return ((750+p[0]*8)*S,(1440-p[1]*7.1)*S)
def poly(points,fill):d.polygon([xy(v) for v in points],fill=fill)
def line(points,width,fill):
 pts=[xy(v) for v in points];w=int(width*7.5*S);r=w/2
 d.line(pts,fill=fill,width=w)
 for x,y in pts:d.ellipse((x-r,y-r,x+r,y+r),fill=fill)
def oval(cx,cz,rx,rz,fill,wobble=False):
 pts=[]
 for i in range(180):
  a=i*math.tau/180;w=1+.035*math.sin(3*a)+.025*math.cos(7*a) if wobble else 1
  pts.append((cx+math.cos(a)*rx*w,cz+math.sin(a)*rz*w))
 poly(pts,fill)
def smooth(pts,closed=False):
 result=[];n=len(pts)
 for i in range(n if closed else n-1):
  a=pts[(i-1)%n] if closed else pts[max(0,i-1)];b=pts[i];c=pts[(i+1)%n];e=pts[(i+2)%n] if closed else pts[min(n-1,i+2)]
  for j in range(20):
   t=j/20;u=1-t
   result.append(tuple(u*u*u*b[k]+3*u*u*t*(b[k]+.16*(c[k]-a[k]))+3*u*t*t*(c[k]-.16*(e[k]-b[k]))+t*t*t*c[k] for k in [0,1]))
 result.append(result[0] if closed else pts[-1]);return result
coast=smooth([(-18,-10),(22,-10),(38,13),(65,24),(72,60),(70,105),(68,151),(36,161),(-10,162),(-60,153),(-72,117),(-73,62),(-71,30),(-42,15)],True)
def expand(points,dist):
 return [(x+x/math.hypot(x,z-76)*dist,z+(z-76)/math.hypot(x,z-76)*dist) for x,z in points]
poly(expand(coast,13),'#8cc8c4');poly(expand(coast,8),'#ead6a5');poly(coast,'#b6c89b')
park=[(-5,34),(15,34),(17,51),(30,56),(38,68),(30,82),(9,88),(-16,84),(-30,72),(-27,61),(-8,52)]
poly(smooth(park,True),'#91b279')
road=[]
for i,(x,z) in enumerate([(47,38.5),(47,82.5),(-35,82.5),(-35,38.5)]):
 for j in range(33):
  a=-math.pi/2+i*math.pi/2+j*math.pi/64
  road.append((x+12*math.cos(a),z+12*math.sin(a)))
road.append(road[0])
line(road,12.5,'#e9dfc8');line(road,8.4,'#768483')
for i in range(0,len(road)-1,5):line(road[i:i+2],.22,'#f2dfae')
for pts,width,closed in [([(5,32),(5,44),(0,54),(-3,63),(2,72),(5,84),(5,100)],3,False),([(-20,61),(0,56),(25,58),(32,69),(23,81),(0,85),(-23,76)],2.5,True),([(-48,68),(-35,66),(-22,67),(-3,65)],2.4,False),([(32,69),(46,71),(59,73)],2.4,False),([(-66,33),(-33,33),(5,33),(51,33)],2.2,False),([(-48,101),(-32,101),(-4,101),(26,101),(57,101)],2.4,False)]:line(smooth(pts,closed),width,'#eee1bc')
oval(17,68,11.5,7.8,'#d3c8aa',True);oval(17,68,10.5,6.8,'#83b8be',True);line([(6,68),(28.3,68)],2.4,'#b58d60')
line([(-48,57),(-65,57),(-79,57)],2.2,'#eee1bc');line([(59,73),(69,73),(78,73)],2.2,'#eee1bc')
line([(4.5,17),(4.5,22)],2.4,'#eee1bc');line([(-15,10),(-15,-6),(4.5,-16)],2.2,'#eee1bc')
for x,z in [(-61,25),(61,29),(-65,91),(66,92),(30,154),(-4,39),(-9,54),(0,87),(34,79),(27,55)]:oval(x,z,1.4,1.4,'#789567')
# Footprints and building labels match the editor and runtime positions.
for name,x,z,w,h,color in [('HOME',0,6,23,18,'#c98f7f'),('GROCERY',-33,45,14,15,'#86a989'),('LIBRARY',-15,45,12,15,'#8daab3'),('BANK',25,45,12,15,'#b7ac83'),('POLICE',43,45,12,15,'#8aa2b4'),('ELECTRONICS',-59.5,45,11.5,15.5,'#8eabb9'),('HOSPITAL',-32,128.2,18,48.4,'#9ab6ba'),('SCHOOL',-4,128.2,20,48.4,'#c7a08e'),('SPORTS',26,116,14,24,'#d7ae60'),('FURNITURE',-52,118,17,29,'#8fa7b0'),('CLOTHING',50.5,112,11,15,'#bfa0ac'),('BAKERY / CAFE',-61,76,14,22,'#c89979')]:
 poly([(x-w/2,z-h/2),(x+w/2,z-h/2),(x+w/2,z+h/2),(x-w/2,z+h/2)],color)
 sx,sy=xy((x,z));text(sx/S,sy/S,name,15 if len(name)>9 else 17,'#203f39')
 if z>100 and name!='BAKERY / CAFE':line([(x,z-h/2),(x,101)],1.8,'#eee1bc')
 if z==45:line([(x,z-h/2),(x,33)],1.8,'#eee1bc')
for z,depth,label in [(76,14,'WILD'),(59,10,'FARM')]:
 poly([(-40,z-depth/2),(-28,z-depth/2),(-28,z+depth/2),(-40,z+depth/2)],'#b4ba88')
 sx,sy=xy((-34,z));text(sx/S,sy/S,label,15)
sx,sy=xy((3,-15));text(sx/S,sy/S,'SOUTH BEACH',18)
sx,sy=xy((-13,72));text(sx/S,sy/S,'Gazebo',17)
sx,sy=xy((12,80));text(sx/S,sy/S,'Play',17)
sx,sy=xy((6,62));text(sx/S,sy/S,'CENTRAL PARK',24)
text(750,72,'VOCABULARY TOWN',44)
text(750,122,'Beach island · Central Park · Zoo',23)
line([(-47,60),(-56,60),(-61,63.2)],2.4,'#eee1bc')
text(750,1585,'Three-floor school & hospital • Park zoo • Beaches',22)
text(750,1625,'M  Close map     |     Buildings and paths are open to explore',20)
text(1375,205,'N\n↑',25)
im.resize((1500,1700),Image.Resampling.LANCZOS).save(f)
print(f)
