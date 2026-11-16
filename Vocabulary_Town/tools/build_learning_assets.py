"""Deterministically author editable Godot scenes. No runtime mesh generation.
Run from any directory with Python 3. All dimensions are local town metres.
"""
from pathlib import Path
import math, json, re
ROOT = Path(__file__).resolve().parents[1]
import sys
sys.path.insert(0, str(ROOT/'tools'))
import word_data  # data/words.json is the only word source
CANONICAL_TRANSLATIONS = word_data.vocabulary(word_data.load())
OUT = ROOT/'scenes/props/vocabulary'
OUT.mkdir(parents=True, exist_ok=True)

def vec(v): return 'Vector3('+', '.join(f'{x:.6f}' for x in v)+')'
def col(c):
    c=c.lstrip('#'); return 'Color('+', '.join(f'{int(c[i:i+2],16)/255:.5f}' for i in (0,2,4))+', 1)'
def slug(s): return s.replace(' ','_')
class Scene:
    def __init__(self, name, word=None, es=None, category=None):
        self.name=name; self.res=[]; self.nodes=[]; self.mats={}; self.n=0; self.ext={}; self.bounds=[]
        self.nodes.append(f'[node name="{name}" type="Node3D"]')
        if word:
            # Spanish and category are not cached in scenes; they come from data/words.json.
            self.nodes += [f'metadata/word_key = "{word}"','metadata/learning_object = true']
    def resource(self,typ,props):
        self.n+=1; rid=f'r{self.n}'; self.res.append(f'[sub_resource type="{typ}" id="{rid}"]\n'+props); return f'SubResource("{rid}")'
    def mat(self,c):
        if c not in self.mats: self.mats[c]=self.resource('StandardMaterial3D',f'albedo_color = {col(c)}\nroughness = 0.78')
        return self.mats[c]
    def mesh(self,name,pos,size,c,typ='BoxMesh',props=None,rot=(0,0,0)):
        if props is None: props=f'size = {vec(size)}'
        mesh=self.resource(typ,props); mat=self.mat(c)
        name=re.sub(r'[^A-Za-z0-9_]','',name)+f'_{self.n}'
        self.nodes += [f'\n[node name="{name}" type="MeshInstance3D" parent="."]',f'position = {vec(pos)}',f'rotation_degrees = {vec(rot)}',f'mesh = {mesh}',f'material_override = {mat}']
        self.bounds.append((pos,size))
    def box(self,name,p,s,c,rot=(0,0,0)): self.mesh(name,p,s,c,rot=rot)
    def ball(self,name,p,s,c):
        # Ellipsoids: scaled low-poly sphere, never used alone to represent an item.
        self.mesh(name,p,s,c,'SphereMesh','radius = 0.5\nheight = 1.0\nradial_segments = 16\nrings = 8')
        self.nodes.append('scale = '+vec(s))
    def cyl(self,name,p,r,h,c,rot=(0,0,0),top=None):
        self.mesh(name,p,(2*r,h,2*r),c,'CylinderMesh',f'top_radius = {r if top is None else top}\nbottom_radius = {r}\nheight = {h}\nradial_segments = 16',rot)
    def ring(self,name,p,r,t,c,rot=(90,0,0),scale=(1,1,1)):
        self.mesh(name,p,(2*(r+t),2*t,2*(r+t)),c,'TorusMesh',f'inner_radius = {r-t}\nouter_radius = {r+t}\nrings = 24\nring_segments = 8',rot)
        self.nodes.append('scale = '+vec(scale))
    def rod(self,name,a,b,r,c):
        d=[b[i]-a[i] for i in range(3)]; h=math.sqrt(sum(x*x for x in d)); p=[(a[i]+b[i])/2 for i in range(3)]
        # Rotation mapping Y to endpoint direction; vertical and planar tubes.
        rot=(math.degrees(math.atan2(d[2],math.sqrt(d[0]**2+d[1]**2))),0,-math.degrees(math.atan2(d[0],d[1])))
        self.cyl(name,p,r,h,c,rot)
    def hit(self,p,s,solid=False,name='Interaction'):
        self.nodes += [f'\n[node name="{name}" type="'+('StaticBody3D' if solid else 'Area3D')+'" parent="."]','collision_layer = '+('1' if solid else '2'),'collision_mask = 0']
        shape=self.resource('BoxShape3D','size = '+vec(s))
        self.nodes += [f'\n[node name="Shape" type="CollisionShape3D" parent="{name}"]','position = '+vec(p),'shape = '+shape]
    def instance(self,key,p,rotation=0):
        path=f'res://scenes/props/vocabulary/{slug(key)}.tscn'
        if path not in self.ext:self.ext[path]=f'e{len(self.ext)+1}'
        self.nodes += [f'\n[node name="{slug(key).title()}" parent="." instance=ExtResource("{self.ext[path]}")]','position = '+vec(p),f'rotation_degrees = Vector3(0, {rotation}, 0)']
    def label(self,text,p,width=0.0045):
        self.nodes += [f'\n[node name="Section{len(self.nodes)}" type="Label3D" parent="."]','position = '+vec(p),f'text = "{text}"','font_size = 52',f'pixel_size = {width}','rotation_degrees = Vector3(0, 180, 0)','modulate = Color(0.18, 0.24, 0.27, 1)','outline_size = 0']
    def save(self,path):
        ex=[f'[ext_resource type="PackedScene" path="{p}" id="{i}"]' for p,i in self.ext.items()]
        path.write_text('[gd_scene format=3]\n\n'+'\n\n'.join(ex+self.res)+'\n\n'+'\n'.join(self.nodes)+'\n')

W='ece8df'; DARK='28343e'; METAL='87949c'; WOOD='ad7b50'; BLUE='467a9b'; GLASS='34536b'; FOOD='d7a254'
# Deleted A1/A2 words are excluded from study even if this old generator is rerun.
# Sports display meshes remain as non-interactive shop decoration.
DEPRECATED_WORDS = set(['aisle sign', 'anatomy', 'anatomy lab', 'armrest', 'atom model', 'awning', 'backrest', 'bagging area', 'bakery shelf', 'banner', 'barbell', 'baseball', 'baseball bat', 'baseball glove', 'baseboard', 'beaker', 'beam', 'bell tower', 'body chart', 'bolt', 'candle stand', 'canister', 'cell', 'coaster', 'column', 'computer desk', 'console table', 'control panel', 'curtain rail', 'desk pad', 'display table', 'dna', 'door frame', 'flagpole', 'floor tile', 'flower bed', 'folded clothes table', 'freezer door', 'gazebo', 'globe stand', 'hanger rail', 'headboard', 'holder', 'hymnal', 'lab bench', 'lab table', 'lampshade', 'leg bone', 'lens', 'microscope', 'mobile demo stand', 'mouse pad', 'nucleus', 'officer desk', 'ottoman', 'partition', 'pavilion', 'payment terminal', 'pelvis', 'petri dish', 'phone display', 'plant tray', 'reference table', 'rib cage', 'roof ridge', 'sale bin', 'science wing', 'sill', 'stained glass', 'stanchion', 'steeple', 'streaming box', 'tank', 'teacher desk', 'telescope', 'tennis ball', 'test tube', 'toilet seat', 'trim', 'umbrella stand', 'vanity', 'vent', 'window sill'])
DECORATIVE_SPORTS = {"baseball glove", "barbell", "baseball bat", "tennis ball", "baseball"}
SIZE_BY_KEY = {}
CATALOG={}
CANONICAL_CATEGORIES = word_data.categories(word_data.load())

def asset(key,es,cat,fn,size):
    # Obsolete specialized teaching assets remain deleted after regeneration.
    if key in DEPRECATED_WORDS and key not in DECORATIVE_SPORTS:
        return
    decorative = key in DECORATIVE_SPORTS
    cat = CANONICAL_CATEGORIES.get(key, cat)
    es = CANONICAL_TRANSLATIONS.get(key, es)  # Preserve reviewed Latin American vocabulary.
    s=Scene(slug(key).title(),None if decorative else key,es,cat);fn(s)
    # Excluded stock items are visual decoration, never clickable word cards.
    if not decorative: s.hit((0,size[1]/2,0),size)
    if size[1]>0.8 and size[0]>0.7: s.hit((0,min(size[1],0.8)/2,0),(size[0]*0.92,min(size[1],0.8),size[2]*0.92),True,'Footprint')
    s.save(OUT/(slug(key)+'.tscn'))
    SIZE_BY_KEY[key]={'spanish':es,'category':cat,'size':size}
    if not decorative: CATALOG[key]=SIZE_BY_KEY[key]

def legs(s,w,d,h):
    for x in [-w/2+.09,w/2-.09]:
        for z in [-d/2+.09,d/2-.09]:s.box('Leg',(x,h/2,z),(.1,h,.1),WOOD)
def table(s,w=1.5,d=.85,h=.85):legs(s,w,d,h-.08);s.box('Top',(0,h-.04,0),(w,.08,d),WOOD)
def chair(s,arm=False):
    legs(s,.85,.8,.5);s.box('Seat',(0,.56,0),(.9,.18,.85),BLUE);s.box('Back',(0,1.02,.34),(.9,.85,.16),BLUE)
    if arm:
        for x in [-.46,.46]:s.box('Arm',(x,.78,0),(.17,.35,.85),BLUE)
def sofa(s):
    legs(s,2.5,.95,.22);s.box('Base',(0,.36,0),(2.5,.35,.95),BLUE);s.box('Back',(0,.9,.4),(2.5,1.1,.2),BLUE)
    for x in [-1.17,1.17]:s.box('Arm',(x,.73,0),(.22,.75,1.05),BLUE)
    for x in [-.73,0,.73]:s.box('Cushion',(x,.62,-.05),(.68,.18,.78),'739db0')
def bed(s):
    legs(s,1.7,2.6,.3);s.box('Frame',(0,.35,0),(1.8,.23,2.7),WOOD);s.box('Mattress',(0,.58,0),(1.65,.3,2.5),W);s.box('Headboard',(0,.95,1.3),(1.9,1.5,.14),WOOD);s.box('Blanket',(0,.75,-.4),(1.67,.07,1.5),BLUE)
    for x in [-.43,.43]:s.ball('Pillow',(x,.83,.76),(.7,.2,.43),W)
def cabinet(s,wardrobe=False):
    w,h,d=(1.7,2.35,.7) if wardrobe else (.8,.78,.6)
    s.box('Carcass',(0,h/2,0),(w,h,d),WOOD)
    for x in [-w/4,w/4]:s.box('Door',(x,h/2,-d/2-.02),(w/2-.025,h-.08,.06),'c79a6a');s.box('Handle',(x*.22,h*.53,-d/2-.08),(.045,.24,.045),DARK)
def bookcase(s):
    for x in [-.7,.7]:s.box('Upright',(x,1.15,0),(.09,2.3,.5),WOOD)
    s.box('Backing',(0,1.15,.23),(1.4,2.3,.055),WOOD)
    for y in [.12,.66,1.2,1.74,2.28]:s.box('Shelf',(0,y,0),(1.4,.07,.5),WOOD)
    for row in range(3):
        for i in range(5):s.box('Book',(-.51+i*.23,.91+row*.54,-.02),(.16,.4,.32),['a15948','416e87','d0b264'][i%3])
def lamp(s):
    s.cyl('Base',(0,.06,0),.32,.12,DARK);s.cyl('Stem',(0,.8,0),.045,1.5,METAL);s.cyl('Shade',(0,1.55,0),.43,.5,'e8cf92',top=.23)
def mirror(s):
    s.box('Frame',(0,1,0),(.9,1.9,.12),WOOD);s.box('Mirror',(0,1,-.07),(.76,1.76,.02),'aacbd3');s.box('Foot',(0,.1,0),(1,.15,.55),WOOD)
furn=[('sofa','el sofá',sofa,(2.6,1.5,1.1)),('armchair','el sillón',lambda s:chair(s,True),(1.1,1.5,.95)),('desk','el escritorio',lambda s:(table(s,1.6,.85),s.box('Drawer',(0,.68,-.36),(1.25,.24,.13),WOOD),s.box('Pull',(0,.68,-.45),(.25,.035,.04),DARK)),(1.6,.9,.9)),('dining table','la mesa de comedor',lambda s:table(s,1.8,1.2),(1.8,.85,1.2)),('wardrobe','el armario',lambda s:cabinet(s,True),(1.75,2.35,.8)),('bed','la cama',bed,(1.9,1.7,2.75)),('bookshelf','la estantería',bookcase,(1.5,2.35,.55)),('nightstand','la mesita de noche / la mesa de noche',cabinet,(.85,.8,.7)),('chair','la silla',chair,(1,1.5,.9)),('coffee table','la mesa de centro',lambda s:table(s,1.3,.75,.46),(1.3,.46,.75)),('lamp','la lámpara',lamp,(.9,1.8,.9)),('mirror','el espejo',mirror,(1,2,.6)),('stool','el taburete',lambda s:(legs(s,.65,.65,.68),s.cyl('Seat',(0,.72,0),.42,.12,WOOD)),(.85,.8,.85)),('bench','el banco',lambda s:(table(s,1.6,.65,.5),s.box('Back',(0,.85,.28),(1.6,.65,.12),WOOD)),(1.6,1.2,.7)),('dresser','la cómoda',lambda s:(s.box('Carcass',(0,.6,0),(1.2,1.2,.6),WOOD),[(s.box('Drawer',(0,y,-.33),(1.1,.31,.07),'c79a6a'),s.box('Handle',(0,y,-.4),(.25,.04,.04),DARK)) for y in [.23,.6,.97]]),(1.25,1.2,.8)),('pillow','la almohada',lambda s:(s.ball('Fabric',(0,.16,0),(.95,.3,.65),W),s.box('Seam',(0,.16,-.31),(.8,.02,.02),'b8b8ac')),(1,.32,.7))]
for k,es,fn,size in furn:asset(k,es,'Furniture',fn,size)

def ball_sport(s,kind):
    color={'basketball':'c87530','soccer ball':'e5e6df','tennis ball':'bfcb47','baseball':'eee5ce','volleyball':'e8c55f'}[kind]
    r=.43 if kind not in ['tennis ball','baseball'] else .24
    s.ball('Ball',(0,r,0),(r*2,)*3,color)
    if kind=='soccer ball':
        for a in range(0,360,72):
            ar=math.radians(a);s.ball('DarkPanel',(math.sin(ar)*r*.85,r+math.cos(ar)*r*.65,-r*.55),(.23,.23,.07),DARK)
        s.ball('FrontPentagon',(0,r,-r*.97),(.27,.27,.045),DARK)
    else:
        for rot in [(90,0,0),(0,0,0),(0,0,90)]:s.ring('Seam',(0,r,0),r,.012,'5f3026' if kind=='basketball' else 'ece9d7',rot)
def racket(s):
    s.ring('OvalFrame',(0,1.15,0),.39,.035,BLUE,scale=(.8,1,1.25))
    for d in [-.2,-.1,0,.1,.2]:
        s.box('VerticalString',(d,1.15,0),(.009,.72,.009),W);s.box('HorizontalString',(0,1.15+d,0),(.55,.009,.009),W)
    s.rod('ThroatL',(-.2,.75,0),(0,.5,0),.025,BLUE);s.rod('ThroatR',(.2,.75,0),(0,.5,0),.025,BLUE);s.box('Grip',(0,.25,0),(.09,.5,.09),DARK)
def bicycle(s):
    for x in [-.75,.75]:
        s.ring('Tire',(x,.48,0),.45,.055,DARK);s.ring('Rim',(x,.48,0),.39,.02,METAL)
        for a in range(0,180,30):
            ar=math.radians(a);s.rod('Spoke',(x-.39*math.cos(ar),.48-.39*math.sin(ar),0),(x+.39*math.cos(ar),.48+.39*math.sin(ar),0),.009,METAL)
    for a,b in [((-.75,.48,0),(-.25,1.12,0)),((-.25,1.12,0),(.1,.48,0)),((.1,.48,0),(-.75,.48,0)),((-.25,1.12,0),(.52,1.1,0)),((.52,1.1,0),(.1,.48,0)),((.52,1.1,0),(.75,.48,0))]:s.rod('FrameTube',a,b,.045,'b7493c')
    s.box('Saddle',(-.25,1.22,0),(.4,.1,.24),DARK);s.rod('HandleStem',(.52,1.1,0),(.48,1.45,0),.035,METAL);s.rod('Handlebar',(.48,1.45,-.3),(.48,1.45,.3),.04,DARK);s.box('Pedal',(.1,.39,-.17),(.28,.06,.17),DARK)
def skateboard(s):
    s.box('Deck',(0,.25,0),(1.35,.09,.38),'b97c45')
    for x in [-.66,.66]:s.box('RaisedNose',(x,.3,0),(.22,.08,.38),'b97c45',rot=(0,0,20 if x>0 else -20))
    for x in [-.42,.42]:
        s.rod('Axle',(x,.14,-.25),(x,.14,.25),.035,METAL)
        for z in [-.23,.23]:s.cyl('Wheel',(x,.13,z),.12,.1,W,(90,0,0))
def helmet(s):
    s.ball('Shell',(0,.38,0),(.8,.64,.75),'be4938');s.box('FaceOpening',(0,.21,-.32),(.54,.25,.12),DARK);s.box('Visor',(0,.43,-.36),(.66,.06,.35),'9c382f')
    for x in [-.19,0,.19]:s.box('AirVent',(x,.65,0),(.07,.035,.28),DARK)
    s.ring('ChinStrap',(0,.18,0),.3,.025,DARK,scale=(.9,1,.7))
def dumbbell(s):
    s.cyl('Grip',(0,.32,0),.065,.9,METAL,(0,0,90))
    for x in [-.45,.45]:s.cyl('Weight',(x,.32,0),.3,.24,DARK,(0,0,90))
def bat(s):s.cyl('Barrel',(0,.85,0),.11,.9,WOOD,top=.13);s.cyl('Handle',(0,.23,0),.055,.45,'564332');s.cyl('Knob',(0,.03,0),.085,.05,WOOD)
def hoop(s):
    s.box('Base',(0,.1,0),(.8,.2,.8),DARK);s.cyl('Post',(0,1.3,.2),.055,2.5,METAL);s.box('Backboard',(0,2.6,.2),(1.3,.85,.08),W);s.box('Target',(0,2.45,.14),(.45,.35,.025),'bb563e');s.ring('Rim',(0,2.3,-.25),.32,.025,'c15a30',rot=(0,0,0))
    for a in range(0,360,60):
        r=math.radians(a);s.rod('Net',(math.sin(r)*.3,2.28,-.25+math.cos(r)*.3),(math.sin(r)*.18,1.85,-.25+math.cos(r)*.18),.012,W)
def goal(s):
    for x in [-.9,.9]:s.rod('Post',(x,0,0),(x,1.2,0),.05,W);s.rod('RearBrace',(x,1.2,0),(x,0,.65),.035,W)
    s.rod('Crossbar',(-.9,1.2,0),(.9,1.2,0),.05,W)
    for x in [-.9,-.6,-.3,0,.3,.6,.9]:s.rod('Net',(x,1.2,.04),(x,0,.65),.012,W)
    for y in [.3,.6,.9]:s.rod('NetRow',(-.9,y,(1.2-y)*.54),(.9,y,(1.2-y)*.54),.012,W)
def glove(s):
    s.ball('Palm',(0,.35,0),(.5,.5,.22),WOOD)
    for i in range(4):s.ball('Finger',(-.2+i*.13,.66+(.06 if i in [1,2] else 0),0),(.12,.43,.19),WOOD)
    s.ball('Thumb',(-.3,.4,0),(.25,.3,.2),WOOD);s.box('Pocket',(0,.42,-.12),(.28,.28,.02),'735237')
sports=[('basketball','el balón de baloncesto',lambda s:ball_sport(s,'basketball'),(.9,.9,.9)),('soccer ball','el balón de fútbol',lambda s:ball_sport(s,'soccer ball'),(.9,.9,.9)),('tennis racket','la raqueta de tenis',racket,(.75,1.7,.16)),('dumbbell','la mancuerna',dumbbell,(1.2,.65,.65)),('helmet','el casco',helmet,(.85,.75,.95)),('bicycle','la bicicleta',bicycle,(2.5,1.55,.7)),('skateboard','el monopatín',skateboard,(1.6,.4,.6)),('baseball bat','el bate de béisbol',bat,(.3,1.35,.3)),('tennis ball','la pelota de tenis',lambda s:ball_sport(s,'tennis ball'),(.5,.5,.5)),('baseball','la pelota de béisbol',lambda s:ball_sport(s,'baseball'),(.5,.5,.5)),('volleyball','el balón de voleibol',lambda s:ball_sport(s,'volleyball'),(.9,.9,.9)),('basketball hoop','la canasta de baloncesto',hoop,(1.4,3.1,1.1)),('goal','la portería',goal,(2,1.3,.8)),('baseball glove','el guante de béisbol',glove,(.85,1,.3)),('barbell','la barra de pesas',lambda s:(s.cyl('Bar',(0,.4,0),.04,1.8,METAL,(0,0,90)),[s.cyl('Plate',(x,.4,0),.38,.14,DARK,(0,0,90)) for x in [-.8,-.64,.64,.8]]),(2,.8,.8)),('jump rope','la cuerda de saltar',lambda s:(s.ring('Rope',(0,.62,0),.48,.025,'b94d3c',scale=(.7,1,1.1)),[s.box('Handle',(x,1.05,0),(.09,.35,.09),DARK) for x in [-.25,.25]]),(.9,1.3,.2))]
for k,es,fn,size in sports:asset(k,es,'Sports',fn,size)

def appliance(s,kind):
    if kind in ['washing machine','dryer']:
        s.box('Cabinet',(0,.72,0),(1.05,1.44,.85),W);s.box('ControlStrip',(0,1.27,-.445),(.97,.22,.045),'bac3c7');s.ring('DoorRim',(0,.64,-.46),.32,.045,METAL);s.cyl('Glass',(0,.64,-.465),.275,.03,GLASS,(90,0,0));s.cyl('Dial',(.3,1.27,-.5),.07,.04,DARK,(90,0,0));s.box('Display',(-.2,1.27,-.49),(.25,.08,.025),DARK)
        if kind=='dryer':
            for x in [-.29,-.15,0,.15,.29]:s.box('Vent',(x,.16,-.44),(.065,.06,.025),DARK)
    elif kind=='refrigerator':
        s.box('Body',(0,1.15,0),(1.05,2.3,.9),W)
        for y,h in [(.85,1.6),(2,.53)]:s.box('Door',(0,y,-.48),(.99,h,.08),'dce2e1');s.box('Handle',(.36,y+.1,-.57),(.06,.35,.07),METAL)
    elif kind=='microwave':
        s.box('Body',(0,.33,0),(1,.66,.65),W);s.box('Door',( -.12,.33,-.34),(.68,.48,.035),DARK);s.box('Window',(-.12,.33,-.365),(.52,.33,.02),GLASS);s.box('Handle',(.2,.33,-.4),(.035,.32,.05),METAL)
        for y in [.19,.31,.43]:s.cyl('Button',(.38,y,-.36),.035,.025,DARK,(90,0,0))
def screen(s,kind):
    if kind in ['television','computer']:
        w,h=(1.8,1.1) if kind=='television' else (1.05,.73)
        s.box('Bezel',(0,.55+h/2,0),(w,h,.12),DARK);s.box('Screen',(0,.55+h/2,-.07),(w-.1,h-.1,.025),GLASS);s.box('Stem',(0,.35,0),(.09,.45,.09),METAL);s.box('Base',(0,.1,0),(w*.5,.06,.35),DARK)
    elif kind=='laptop':
        s.box('Base',(0,.06,0),(1,.08,.68),METAL);s.box('Keyboard',(0,.11,-.07),(.84,.025,.32),DARK);s.box('Trackpad',(0,.11,-.28),(.28,.015,.12),'aab3b8');s.box('Lid',(0,.47,.27),(1,.8,.07),DARK);s.box('Screen',(0,.47,.225),(.89,.68,.02),GLASS)
    else:
        w,h=(.42,.78) if kind in ['smartphone','phone'] else (.85,1.1)
        s.box('Body',(0,h/2,0),(w,h,.08),DARK);s.box('Screen',(0,h/2,-.05),(w-.06,h-.13,.02),GLASS);s.cyl('Camera',(0,h-.04,-.06),.018,.012,DARK,(90,0,0));s.box('HomeIndicator',(0,.04,-.06),(w*.35,.015,.01),W)
def headphones(s):
    s.ring('Headband',(0,.55,0),.4,.045,DARK,scale=(1,1,1.2))
    for x in [-.37,.37]:s.box('EarCup',(x,.32,0),(.2,.4,.25),BLUE);s.box('Padding',(x*.82,.32,0),(.07,.31,.22),DARK)
def speaker(s):
    s.box('Cabinet',(0,.55,0),(.6,1.1,.48),DARK)
    for y,r in [(.34,.19),(.82,.09)]:s.cyl('Cone',(0,y,-.255),r,.04,METAL,(90,0,0));s.cyl('DustCap',(0,y,-.28),r*.45,.025,DARK,(90,0,0))
def camera(s):
    s.box('Body',(0,.32,0),(.75,.48,.35),DARK);s.box('Viewfinder',(0,.62,0),(.26,.16,.27),DARK);s.cyl('Lens',(0,.32,-.3),.2,.3,DARK,(90,0,0));s.cyl('Glass',(0,.32,-.46),.15,.02,GLASS,(90,0,0));s.cyl('Shutter',(.25,.58,0),.055,.04,METAL)
def fan(s):
    s.cyl('Base',(0,.06,0),.4,.12,DARK);s.cyl('Pole',(0,.7,0),.05,1.3,METAL);s.ring('Guard',(0,1.55,0),.47,.025,METAL)
    for a in [0,120,240]:
        r=math.radians(a);s.ball('Blade',(math.cos(r)*.21,1.55+math.sin(r)*.21,0),(.36,.16,.06),BLUE)
    for a in range(0,180,30):
        r=math.radians(a);s.rod('GuardWire',(-.46*math.cos(r),1.55-.46*math.sin(r),-.08),(.46*math.cos(r),1.55+.46*math.sin(r),-.08),.009,METAL)
    s.cyl('Hub',(0,1.55,-.1),.08,.06,DARK,(90,0,0))
def keyboard(s):
    s.box('Base',(0,.06,0),(1,.1,.4),DARK)
    for i in range(10):
        for j in range(3):s.box('Key',(-.44+i*.095,.12,-.13+j*.1),(.07,.04,.07),W)
def controller(s):
    s.box('Bridge',(0,.25,0),(.6,.23,.28),DARK)
    for x in [-.28,.28]:s.ball('Grip',(x,.18,0),(.25,.35,.35),DARK)
    s.box('Dpad',(-.2,.39,0),(.05,.025,.17),W);s.box('Dpad',(-.2,.39,0),(.17,.025,.05),W)
    for x,z in [(.17,-.07),(.25,0),(.17,.07)]:s.cyl('Button',(x,.39,z),.035,.025,'ba5145')
electro=[('television','el televisor',lambda s:screen(s,'television'),(1.85,1.7,.4)),('smartphone','el teléfono inteligente',lambda s:screen(s,'smartphone'),(.46,.8,.15)),('laptop','el portátil',lambda s:screen(s,'laptop'),(1.05,.9,.75)),('tablet','la tableta',lambda s:screen(s,'tablet'),(.9,1.12,.15)),('washing machine','la lavadora',lambda s:appliance(s,'washing machine'),(1.1,1.45,1)),('dryer','la secadora',lambda s:appliance(s,'dryer'),(1.1,1.45,1)),('refrigerator','el refrigerador',lambda s:appliance(s,'refrigerator'),(1.1,2.35,1.1)),('microwave','el microondas',lambda s:appliance(s,'microwave'),(1.05,.68,.85)),('headphones','los auriculares',headphones,(1,.99,.3)),('speaker','el altavoz',speaker,(.65,1.12,.6)),('camera','la cámara',camera,(.8,.72,.85)),('fan','el ventilador',fan,(1,2.05,.8)),('keyboard','el teclado',keyboard,(1.05,.15,.45)),('computer','el ordenador',lambda s:screen(s,'computer'),(1.1,1.3,.45)),('game controller','el mando de videojuegos',controller,(.9,.42,.5)),('mouse','el ratón',lambda s:(s.ball('Shell',(0,.12,0),(.3,.22,.48),W),s.box('ButtonSeam',(0,.2,-.1),(.012,.03,.2),DARK),s.cyl('Wheel',(0,.24,-.1),.035,.05,DARK,(90,0,0))),(.35,.28,.5))]
for k,es,fn,size in electro:asset(k,es,'Electronics',fn,size)

def bread(s):
    s.ball('Loaf',(0,.25,0),(1.15,.48,.6),FOOD)
    for x in [-.35,0,.35]:s.box('Score',(x,.475,0),(.055,.018,.3),'f0d9a0',rot=(0,25,0))
def croissant(s):
    for i in range(9):
        a=math.radians(35+i*14);r=.42;w=.14+.17*math.sin(math.pi*i/8)
        s.ball('Fold',(math.cos(a)*r,.18,math.sin(a)*r-.28),(w,.3,w*.95),FOOD)
def cake(s):
    s.cyl('Sponge',(0,.32,0),.55,.6,FOOD);s.cyl('CreamLayer',(0,.32,0),.56,.09,W);s.cyl('Icing',(0,.64,0),.57,.09,'f0d5c7')
    for i in range(6):
        a=i*math.tau/6;s.ball('Strawberry',(math.cos(a)*.36,.74,math.sin(a)*.36),(.15,.17,.15),'bb4539')
def donut(s):s.ring('Dough',(0,.16,0),.32,.13,FOOD,rot=(0,0,0));s.ring('Icing',(0,.22,0),.32,.09,'d894a5',rot=(0,0,0))
def cookie(s):
    s.cyl('Dough',(0,.07,0),.4,.14,FOOD)
    for x,z in [(-.2,0),(.15,.1),(0,-.18),(.2,-.13),(-.1,.2)]:s.ball('ChocolateChip',(x,.145,z),(.08,.04,.07),'593f30')
def cup(s,tea=False):
    s.cyl('Body',(0,.25,0),.22,.48,W,top=.27);s.cyl('Drink',(0,.495,0),.235,.015,'61432e');s.ring('Handle',(.29,.28,0),.14,.035,W,scale=(1,1,1));s.cyl('Saucer',(0,.015,0),.38,.03,W)
def teapot(s):
    s.ball('Pot',(0,.35,0),(.65,.6,.6),W);s.cyl('Lid',(0,.67,0),.21,.06,W);s.ball('Knob',(0,.73,0),(.1,.1,.1),DARK);s.ring('Handle',(.4,.36,0),.22,.035,W);s.rod('Spout',(-.23,.3,0),(-.54,.65,0),.09,W)
def coffee_machine(s):
    s.box('Body',(0,.5,0),(.9,1,.55),METAL);s.box('Front',(0,.58,-.3),(.78,.64,.05),DARK);s.box('DripTray',(0,.1,-.38),(.85,.08,.48),METAL)
    for x in [-.2,.2]:s.cyl('Button',(x,.8,-.35),.06,.04,'d5ac54',(90,0,0));s.cyl('Spout',(x,.45,-.42),.035,.23,METAL)
    s.box('SteamWand',(.43,.35,-.36),(.035,.45,.035),METAL);s.box('Display',(0,.93,-.32),(.2,.08,.02),GLASS)
def rolling(s):
    s.cyl('Roller',(0,.15,0),.14,.75,WOOD,(0,0,90));s.cyl('Handles',(0,.15,0),.055,1.15,WOOD,(0,0,90))
def whisk(s):
    s.cyl('Grip',(0,.22,0),.05,.44,WOOD)
    for a in [0,45,90]:s.ring('WireLoop',(0,.67,0),.19,.009,METAL,rot=(90,a,0),scale=(.7,1,1.5))
def bowl(s):
    s.cyl('Bowl',(0,.2,0),.22,.4,W,top=.44);s.cyl('Interior',(0,.4,0),.39,.012,'b8c7cb');s.ring('Rim',(0,.4,0),.42,.025,W,rot=(0,0,0))
def plate(s):s.cyl('Base',(0,.035,0),.44,.06,W);s.ring('Rim',(0,.07,0),.4,.025,W,rot=(0,0,0));s.cyl('Well',(0,.07,0),.32,.015,'d7dace')
def spoon(s):s.box('Handle',(0,.04,.1),(.055,.04,.6),METAL);s.ball('Bowl',(0,.055,-.3),(.2,.07,.28),METAL)
def knife(s):s.box('Grip',(0,.06,.25),(.12,.1,.38),WOOD);s.box('Blade',(.025,.07,-.18),(.19,.025,.53),METAL)
def apron(s):
    s.box('Bib',(0,.85,0),(.48,.6,.06),'eee3cc');s.mesh('Skirt',(0,.3,0),(.75,.6,.06),'eee3cc','PrismMesh','size = Vector3(0.8, 0.7, 0.08)');s.ring('NeckStrap',(0,1.22,0),.16,.025,'bd8262');s.box('Pocket',(0,.45,-.045),(.3,.2,.025),'bd8262')
bakery=[('bread','el pan',bread,(1.2,.5,.65)),('croissant','el cruasán',croissant,(1,.4,.65)),('cake','la tarta',cake,(1.2,.85,1.2)),('donut','la rosquilla',donut,(1,.34,1)),('cookie','la galleta',cookie,(.85,.18,.85)),('coffee maker','la cafetera',coffee_machine,(1,1.05,.95)),('cup','la taza',cup,(.85,.53,.8)),('teapot','la tetera',teapot,(1.25,.8,.7)),('rolling pin','el rodillo',rolling,(1.2,.32,.32)),('whisk','el batidor',whisk,(.5,1,.4)),('bowl','el cuenco',bowl,(.95,.46,.95)),('plate','el plato',plate,(.95,.12,.95)),('spoon','la cuchara',spoon,(.25,.1,.9)),('knife','el cuchillo',knife,(.25,.14,1)),('apron','el delantal',apron,(.85,1.45,.18)),('baguette','la baguette',lambda s:(s.ball('Loaf',(0,.17,0),(.42,.32,1.4),FOOD),[s.box('Score',(0,.32,z),(.28,.02,.045),'f0d9a0',rot=(0,25,0)) for z in [-.4,-.1,.2,.5]]),(.5,.35,1.45))]
for k,es,fn,size in bakery:asset(k,es,'Bakery and café',fn,size)

def fruit(s,kind):
    if kind in ['apple','orange','lemon','pear','tomato','peach']:
        c={'apple':'b94736','orange':'e58828','lemon':'dfcf3c','pear':'b6bb50','tomato':'ce4934','peach':'df9760'}[kind]
        s.ball('Fruit',(0,.32,0),(.65,.62,.62),c)
        if kind=='pear':s.ball('Neck',(0,.62,0),(.35,.4,.35),c)
        if kind=='lemon':
            for x in [-.34,.34]:s.ball('Tip',(x,.32,0),(.15,.18,.2),c)
        if kind=='orange':
            for a in range(0,360,60):
                r=math.radians(a);s.ball('PeelDimple',(.3*math.sin(r),.32+.2*math.cos(r),-.2),(.025,.025,.025),'bd741f')
        s.rod('Stem',(0,.6,0),(0,.77,.02),.025,WOOD);s.ball('Leaf',(.12,.68,0),(.25,.05,.12),'527d3e')
    elif kind=='banana':
        for i in range(7):
            a=math.radians(-65+i*20);s.ball('CurvedPeel',(.45*math.sin(a),.18+.3*(1-math.cos(a)),0),(.25,.22,.24),'e8ce4b')
        for x in [-.44,.44]:s.box('Tip',(x,.36,0),(.07,.09,.09),'78623b')
    elif kind=='carrot':
        s.cyl('TaperedRoot',(0,.35,0),.035,.65,'dc7c2d',top=.18)
        for x in [-.14,0,.14]:s.rod('Leaf',(0,.68,0),(x,1,.04),.035,'4a7b3f')
    elif kind=='broccoli':
        s.cyl('Stalk',(0,.22,0),.1,.4,'93af57')
        for x,y,z in [(-.2,.5,0),(.2,.5,0),(0,.6,0),(0,.47,.2),(0,.47,-.2)]:s.ball('Floret',(x,y,z),(.4,.34,.4),'508047')
    elif kind=='grapes':
        for row in range(4):
            for i in range(4-row):s.ball('Grape',((i-(3-row)/2)*.17,.65-row*.17,0),(.23,.23,.23),'725385')
        s.rod('Stem',(0,.68,0),(0,.88,0),.025,WOOD)
    elif kind=='watermelon':
        s.ball('Melon',(0,.4,0),(1,.78,.8),'537c40')
        for x in [-.3,0,.3]:s.ring('Stripe',(x,.4,0),.36,.025,'8da54d',rot=(0,0,90),scale=(1,1,.95))
    elif kind=='potato':
        s.ball('Potato',(0,.22,0),(.7,.42,.52),'b89b69')
        for x,z in [(-.18,0),(.14,.12),(.1,-.13)]:s.ball('Eye',(x,.41,z),(.045,.025,.045),'7f6848')
def carton(s):
    s.box('Carton',(0,.4,0),(.5,.8,.5),W);s.mesh('FoldedTop',(0,.89,0),(.5,.22,.5),BLUE,'PrismMesh','size = Vector3(0.5, 0.22, 0.5)');s.box('Seam',(0,1.02,0),(.5,.045,.045),W);s.box('Band',(0,.45,-.26),(.45,.22,.02),BLUE)
def cheese(s):
    s.mesh('Wedge',(0,.23,0),(.8,.45,.6),'e7bd4f','PrismMesh','size = Vector3(0.8, 0.45, 0.6)',rot=(0,0,90))
    for x,y in [(-.15,.17),(.1,.22),(.25,.12)]:s.cyl('Hole',(x,y,-.31),.045,.012,'b58d32',(90,0,0))
def eggs(s):
    s.box('CartonBase',(0,.07,0),(.9,.14,.58),'b2a587')
    for x in [-.28,0,.28]:
        for z in [-.14,.14]:s.ball('Egg',(x,.28,z),(.23,.35,.23),'eee4cb')
def fish(s):
    s.ball('Body',(0,.22,0),(.85,.4,.23),'8facb5');s.mesh('Tail',(.55,.22,0),(.35,.45,.09),'7796a3','PrismMesh','size = Vector3(0.35, 0.45, 0.09)',rot=(0,0,90));s.ball('Eye',(-.28,.3,-.12),(.065,.065,.03),DARK);s.box('Gill',(-.15,.23,-.12),(.02,.2,.02),DARK)
def steak(s):
    s.ball('Meat',(0,.12,0),(.9,.22,.65),'b55049');s.ring('Fat',(0,.19,0),.28,.035,'ead6b8',rot=(0,0,0),scale=(1.2,1,.8));s.ball('Bone',(-.1,.23,0),(.17,.035,.23),W)
def bottle(s):
    s.cyl('Body',(0,.35,0),.22,.65,'9bb7c1');s.cyl('Shoulder',(0,.73,0),.22,.13,'9bb7c1',top=.09);s.cyl('Neck',(0,.87,0),.09,.17,'9bb7c1');s.cyl('Cap',(0,.98,0),.11,.07,BLUE)
def cereal(s):
    s.box('Package',(0,.6,0),(.65,1.2,.26),'d3ab52');s.ball('BowlPicture',(0,.39,-.14),(.45,.22,.025),W)
    for x,y in [(-.15,.68),(.05,.77),(.15,.61)]:s.ring('CerealPicture',(x,y,-.15),.055,.015,'a57338')
def can(s):
    s.cyl('Tin',(0,.28,0),.24,.55,METAL);s.cyl('PaperBand',(0,.27,0),.245,.4,'68945e');s.ring('TopRim',(0,.56,0),.22,.015,METAL,rot=(0,0,0));s.ring('PullTab',(0,.58,0),.06,.014,DARK,rot=(0,0,0),scale=(1,1,.65))
grocery=[]
for k,es in [('apple','la manzana'),('orange','la naranja'),('banana','el plátano'),('lemon','el limón'),('pear','la pera'),('tomato','el tomate'),('carrot','la zanahoria'),('broccoli','el brócoli'),('grapes','las uvas'),('watermelon','la sandía'),('potato','la patata')]:
    size=(1.1,.85,.9) if k=='watermelon' else (.85,1.05 if k=='carrot' else .9,.8)
    grocery.append((k,es,lambda s,k=k:fruit(s,k),size))
grocery += [('milk','la leche',carton,(.55,1.08,.55)),('cheese','el queso',cheese,(.9,.65,.7)),('eggs','los huevos',eggs,(.95,.5,.65)),('fish','el pescado',fish,(1.3,.5,.35)),('steak','el filete',steak,(1,.3,.75)),('water bottle','la botella de agua',bottle,(.5,1.05,.5)),('cereal','los cereales',cereal,(.7,1.25,.35)),('can','la lata',can,(.55,.65,.55))]
for k,es,fn,size in grocery:asset(k,es,'Groceries',fn,size)
# Bread is deliberately reused in the market; one canonical metadata key.

# Clothing: silhouettes include sleeves, collars, legs, brims and soles.
def garment(s,kind):
    c='688da4' if kind in ['shirt','pants','jacket','jeans'] else 'be798c'
    if kind in ['shirt','jacket','sweater','coat']:
        h=1.1 if kind=='coat' else .75
        s.box('Torso',(0,h/2,0),(.6,h,.14),c)
        for x in [-.43,.43]:s.box('Sleeve',(x,h-.2,0),(.3,.42 if kind=='shirt' else .7,.14),c,rot=(0,0,25 if x>0 else -25))
        s.ring('Collar',(0,h,0),.13,.025,W,rot=(0,0,0))
        if kind in ['jacket','coat']:
            s.box('Zip',(0,h/2,-.09),(.025,h,.02),DARK)
            for x in [-.18,.18]:s.box('Pocket',(x,.25,-.09),(.15,.17,.02),DARK)
    elif kind in ['pants','jeans','shorts']:
        h=.55 if kind=='shorts' else 1.1
        s.box('Waist',(0,h-.09,0),(.65,.18,.16),c)
        for x in [-.18,.18]:s.box('Leg',(x,(h-.15)/2,0),(.27,h-.15,.16),c)
        s.box('Belt',(0,h-.03,-.09),(.65,.045,.02),DARK)
    elif kind in ['dress','skirt']:
        s.mesh('FlaredSkirt',(0,.36,0),(.85,.7,.2),c,'PrismMesh','size = Vector3(0.85, 0.7, 0.2)')
        if kind=='dress':s.box('Bodice',(0,.85,0),(.45,.45,.15),c);s.box('WaistBand',(0,.6,-.09),(.52,.06,.02),W)
    elif kind in ['shoes','sneakers','boots']:
        for x in [-.23,.23]:
            s.ball('Shoe',(x,.16,-.08),(.36,.3,.7),c);s.box('Sole',(x,.04,-.08),(.37,.07,.68),W)
            if kind=='boots':s.box('Shaft',(x,.42,.1),(.3,.6,.3),c)
            else:
                for z in [-.16,-.04,.08]:s.box('Lace',(x,.3,z),(.23,.02,.025),W)
    elif kind=='hat':s.cyl('Brim',(0,.04,0),.48,.07,'c3a271');s.cyl('Crown',(0,.23,0),.3,.35,'c3a271');s.cyl('Band',(0,.12,0),.31,.08,DARK)
    elif kind=='belt':s.ring('Strap',(0,.1,0),.38,.035,WOOD,rot=(0,0,0),scale=(1,1,.7));s.box('Buckle',(0,.1,-.28),(.19,.15,.045),METAL);s.box('BuckleHole',(0,.1,-.31),(.1,.07,.02),DARK)
    elif kind=='scarf':s.box('LongEnd',(-.12,.45,0),(.24,.9,.05),c);s.box('ShortEnd',(.12,.63,0),(.24,.65,.05),c);s.ring('Loop',(0,1,0),.23,.06,c,rot=(0,0,0))
    elif kind=='handbag':s.box('Bag',(0,.3,0),(.7,.6,.25),WOOD);s.ring('Handle',(0,.77,0),.21,.035,WOOD);s.box('Clasp',(0,.48,-.15),(.12,.1,.03),METAL)
    elif kind=='sunglasses':
        for x in [-.23,.23]:s.ring('Frame',(x,.2,0),.18,.025,DARK);s.cyl('Lens',(x,.2,0),.16,.025,GLASS,(90,0,0));s.rod('Arm',(x*1.7,.2,0),(x*1.7,.2,.4),.025,DARK)
        s.box('Bridge',(0,.22,0),(.12,.03,.03),DARK)
clothes=[]
for k,es in [('shirt','la camisa'),('jacket','la chaqueta'),('sweater','el jersey'),('coat','el abrigo'),('pants','los pantalones'),('jeans','los vaqueros'),('shorts','los pantalones cortos'),('dress','el vestido'),('skirt','la falda'),('shoes','los zapatos'),('sneakers','las zapatillas'),('boots','las botas'),('hat','el sombrero'),('belt','el cinturón'),('scarf','la bufanda'),('handbag','el bolso'),('sunglasses','las gafas de sol')]:
    size=(1.25,1.25,.35) if k in ['shirt','jacket','sweater','coat'] else (.95,1.25,.8)
    clothes.append((k,es,lambda s,k=k:garment(s,k),size));asset(k,es,'Clothing',clothes[-1][2],size)

# Existing school and clinic vocabulary receives recognizable replacement props.
def stethoscope(s):
    s.ring('Tubing',(0,.34,0),.22,.027,DARK,scale=(1,1,1.15))
    for x in [-.13,.13]:
        s.rod('EarTube',(x,.52,0),(x*1.35,.79,0),.018,METAL)
        s.ball('EarTip',(x*1.35,.81,0),(.065,.08,.065),DARK)
    s.rod('Tail',(.2,.27,0),(.3,.08,0),.022,DARK)
    s.cyl('Chestpiece',(.3,.06,0),.09,.045,METAL,(90,0,0))
def medicine(s):
    s.cyl('Bottle',(0,.22,0),.17,.4,'ac794a');s.cyl('ChildproofCap',(0,.46,0),.19,.09,W);s.box('Label',(0,.23,-.175),(.25,.25,.015),W);s.box('Cross',(0,.23,-.19),(.055,.19,.015),'aa453c');s.box('Cross',(0,.23,-.19),(.19,.055,.015),'aa453c')
def thermometer(s):
    s.box('Probe',(0,.32,0),(.07,.6,.05),W);s.box('DisplayHousing',(0,.47,0),(.16,.28,.09),W);s.box('LCD',(0,.5,-.055),(.12,.12,.02),'708f82');s.cyl('Tip',(0,.035,0),.025,.08,METAL)
def bandage(s):
    s.box('Strip',(0,.035,0),(.7,.05,.22),'d0aa85');s.box('Pad',(0,.07,0),(.25,.035,.19),W)
    for x in [-.25,-.17,.17,.25]:
        for z in [-.05,.05]:s.cyl('Perforation',(x,.065,z),.012,.01,'88694f')
def iv(s):
    s.cyl('Pole',(0,1.1,0),.035,2.15,METAL)
    for a in range(0,360,90):
        r=math.radians(a);s.rod('Foot',(0,.12,0),(.35*math.cos(r),.08,.35*math.sin(r)),.025,METAL)
        s.ball('Caster',(.35*math.cos(r),.06,.35*math.sin(r)),(.1,.12,.1),DARK)
    s.rod('Hanger',(-.27,2.1,0),(.27,2.1,0),.025,METAL);s.box('FluidBag',(.2,1.77,0),(.25,.42,.12),'bacfd2');s.rod('Tube',(.2,1.55,0),(.2,.6,0),.009,'bdd3cf')
def wheelchair(s):
    for x in [-.43,.43]:
        s.ring('RearWheel',(x,.48,.15),.43,.045,DARK,rot=(0,0,90))
        s.ring('PushRim',(x*1.1,.48,.15),.34,.018,METAL,rot=(0,0,90))
        for a in range(0,180,45):
            r=math.radians(a);s.rod('Spoke',(x,.48-.4*math.cos(r),.15-.4*math.sin(r)),(x,.48+.4*math.cos(r),.15+.4*math.sin(r)),.012,METAL)
        s.rod('Frame',(x,.22,-.3),(x,1.1,.3),.025,METAL);s.rod('PushHandle',(x,1.1,.3),(x,1.1,.53),.03,DARK)
        s.cyl('Caster',(x,.1,-.45),.1,.08,DARK,(0,0,90));s.box('Armrest',(x,.86,0),(.1,.08,.6),DARK)
    s.box('Seat',(0,.52,0),(.7,.09,.6),BLUE);s.box('Backrest',(0,.81,.29),(.7,.6,.1),BLUE);s.box('Footrest',(0,.15,-.55),(.7,.05,.25),DARK)
def crutches(s):
    for side in [-.18,.18]:
        for x in [-.09,.09]:s.rod('Upright',(side+x,1.5,0),(side,.35,0),.022,WOOD)
        s.box('Underarm',(side,1.5,0),(.28,.09,.12),DARK);s.box('Handgrip',(side,.95,0),(.2,.045,.07),DARK);s.rod('Lower',(side,.35,0),(side,0,0),.025,WOOD);s.cyl('RubberFoot',(side,.03,0),.04,.06,DARK)
def microscope(s):
    s.box('Base',(0,.07,0),(.55,.13,.45),W);s.rod('Support',(.18,.12,.12),(.18,.73,.12),.065,W);s.box('Stage',(0,.38,0),(.42,.05,.3),DARK);s.cyl('OpticalTube',(-.08,.69,0),.07,.4,W,(0,0,-25));s.cyl('Eyepiece',(-.18,.89,0),.06,.14,DARK,(0,0,-25));s.cyl('Objective',(0,.48,0),.045,.13,METAL)
    s.cyl('FocusWheel',(.25,.62,.12),.09,.055,DARK,(0,0,90));s.cyl('Lamp',(0,.19,0),.085,.08,METAL)
def notebook(s):
    s.box('Cover',(0,.025,0),(.52,.05,.7),BLUE);s.box('Pages',(0,.07,0),(.47,.06,.65),W)
    for z in [-.25,-.15,-.05,.05,.15,.25]:s.ring('Spiral',(-.25,.09,z),.045,.01,METAL,rot=(0,0,90))
    for z in [-.2,-.1,0,.1,.2]:s.box('Rule',(0,.105,z),(.35,.003,.005),'9eaeb0')
def pencil(s):
    s.cyl('HexagonalBody',(0,.39,0),.045,.66,'e1b74a');s.cyl('WoodTip',(0,.05,0),.045,.1,WOOD,top=0);s.cyl('Eraser',(0,.76,0),.047,.1,'ce8b8b');s.cyl('Ferrule',(0,.7,0),.048,.07,METAL)
def globe(s):
    s.cyl('Base',(0,.04,0),.26,.08,DARK);s.cyl('Stem',(0,.22,0),.04,.36,METAL);s.ball('Ocean',(0,.63,0),(.7,.7,.7),BLUE);s.ring('Meridian',(0,.63,0),.39,.018,METAL)
    for p,sz in [((-.13,.73,-.31),(.21,.25,.04)),((.1,.52,-.32),(.12,.22,.04)),((.22,.78,-.22),(.22,.14,.13)),((-.2,.72,.23),(.18,.25,.12))]:s.ball('Continent',p,sz,'70914c')
for k,es,fn,size in [('stethoscope','el estetoscopio',stethoscope,(.7,.87,.15)),('medicine','el medicamento',medicine,(.42,.52,.42)),('thermometer','el termómetro',thermometer,(.2,.65,.15)),('bandage','la venda',bandage,(.75,.12,.27)),('iv stand','el soporte para suero',iv,(.8,2.2,.8)),('wheelchair','la silla de ruedas',wheelchair,(1.1,1.2,1.35)),('crutches','las muletas',crutches,(.7,1.6,.2)),('microscope','el microscopio',microscope,(.65,1,.55)),('notebook','el cuaderno',notebook,(.65,.15,.75)),('pencil','el lápiz',pencil,(.15,.85,.15)),('globe','el globo terráqueo',globe,(.85,1.05,.85))]:
    asset(k,es,'School' if k in ['microscope','notebook','pencil','globe'] else 'Hospital',fn,size)

# Rooms use display islands at the perimeter and generous clear center aisles.
# Furniture is floor-standing; smaller vocabulary sits at eye-friendly 1.0m.
def shell(s,w,d,title,accent):
    s.box('Floor',(0,-.02,0),(w,.1,d),'e4dfd2');s.hit((0,-.02,0),(w,.1,d),True,'FloorBody')
    for name,p,sz in [('Rear',(0,2.3,d/2),(w,4.6,.18)),('Left',(-w/2,2.3,0),(.18,4.6,d)),('Right',(w/2,2.3,0),(.18,4.6,d)),('FrontLeft',(-(w/2+1.8)/2,2.3,-d/2),((w-3.6)/2,4.6,.18)),('FrontRight',((w/2+1.8)/2,2.3,-d/2),((w-3.6)/2,4.6,.18)),('Lintel',(0,4,-d/2),(3.6,1.2,.18))]:
        s.box(name,p,sz,'e4e7e3');s.hit(p,sz,True,name+'Body')
    s.box('Roof',(0,4.7,0),(w+.3,.18,d+.3),accent);s.box('SignBoard',(0,3.75,-d/2-.14),(w-.5,.75,.1),accent);s.label(title,(0,3.75,-d/2-.21),.007)
    for z in [-d*.28,d*.28]:
        s.nodes += [f'\n[node name="InteriorLight{len(s.nodes)}" type="OmniLight3D" parent="."]','position = '+vec((0,3.8,z)),'light_energy = 0.65','omni_range = 11.0','omni_attenuation = 0.6','shadow_enabled = false']
    s.box('EntrancePath',(0,.025,-d/2-1.5),(3.5,.04,3),'d8d5cb')

def display(s,key,p,angle=0,depth=1.4):
    h=SIZE_BY_KEY[key]['size'][1]
    small = h<1.4 and (SIZE_BY_KEY[key]['category']!='Furniture' or key=='pillow')
    if small:
        s.box('DisplayTop'+slug(key),(p[0],.96,p[2]),(1.55,.1,depth),'c7b596')
        s.hit((p[0],.96,p[2]),(1.55,.1,depth),True,'DisplayBody'+slug(key))
        for dx in [-.55,.55]:s.box('DisplayLeg',(p[0]+dx,.47,p[2]),(.09,.94,max(.5,depth-.2)),WOOD)
        p=(p[0],1.02,p[2])
    s.instance(key,p,angle)

def room(filename,title,keys,w=14,d=18,accent='7fa59a',existing=False):
    s=Scene(title.replace(' ','').replace('&','And'))
    if not existing:shell(s,w,d,title,accent)
    elif title=='FRESH MARKET':s.box('MarketTileFloor',(0,.06,0),(w-.3,.04,d-.3),'e2ddcb')
    # Two side galleries with 2.7m between consecutive small displays.
    # Furniture uses wider 3.5m bays; rear row remains accessible from the center.
    nside=(len(keys)+1)//2
    step=(d-4)/max(1,nside-1)
    for i,key in enumerate(keys):
        side=-1 if i<nside else 1;j=i if i<nside else i-nside
        x=side*(w/2-1.65);z=-d/2+2+j*step
        display(s,key,(x,.10,z),-90 if side<0 else 90, min(1.4,step-.15))
    # Vocabulary objects carry no text labels; section headings support navigation.
    headings={'SPORTS':('BALLS & RACKETS','EQUIPMENT'),'FURNITURE':('LIVING & DINING','BEDROOM & STORAGE'),'BAKERY & CAFE':('BAKED GOODS & COFFEE','TABLEWARE & BAKING'),'ELECTRONICS':('SCREENS & COMPUTERS','APPLIANCES & AUDIO'),'FRESH MARKET':('FRUIT & VEGETABLES','DAIRY & GROCERIES'),'CLOTHING':('TOPS & BOTTOMS','SHOES & ACCESSORIES')}
    left,right=headings[title]
    s.label(left,(-w/2+1.8,2.85,-d/2+1.0),.0045)
    s.label(right,(w/2-1.8,2.85,-d/2+1.0),.0045)
    s.save(ROOT/'scenes/buildings'/filename)

# Furniture showroom: eight spacious 3.4m bays on each side. Wider footprint
# extends west of the old annex plot, avoiding the hospital immediately east.
room('sports_store.tscn','SPORTS', ['basketball','soccer ball','volleyball','tennis ball','baseball','baseball glove','baseball bat','tennis racket','bicycle','skateboard','helmet','dumbbell','barbell','jump rope','basketball hoop','goal'],14,24,'d7ae60')
room('furniture_store.tscn','FURNITURE',['sofa','armchair','chair','bench','stool','dining table','desk','coffee table','bed','wardrobe','bookshelf','dresser','nightstand','lamp','mirror','pillow'],17,29,'8fa7b0')
room('bakery_cafe.tscn','BAKERY & CAFE',['bread','baguette','croissant','cake','donut','cookie','coffee maker','teapot','cup','bowl','plate','spoon','knife','rolling pin','whisk','apron'],14,22,'c89979')
# Retain electronics exterior exactly; replace its old dense interior.
e=ROOT/'scenes/buildings/electronics_store.tscn'
original=e.read_text()
# Shell ends at first interior desk. Rebuilding repeatedly is safe using marker.
marker='[node name="ComputerDesk"'
if marker in original: original=original[:original.index(marker)]
if 'id="learning_display"' not in original:
    original=original.replace('[node name="ElectronicsStore"', '[node name="ElectronicsStore"')
    idx=original.index('[sub_resource')
    original=original[:idx]+'[ext_resource type="PackedScene" path="res://scenes/buildings/electronics_displays.tscn" id="learning_display"]\n\n'+original[idx:]
    original += '\n[node name="LearningDisplays" parent="." instance=ExtResource("learning_display")]\n'
e.write_text(original)
room('electronics_displays.tscn','ELECTRONICS',['television','computer','laptop','smartphone','tablet','keyboard','mouse','game controller','washing machine','dryer','refrigerator','microwave','headphones','speaker','camera','fan'],11.3,15.2,existing=True)
room('market_displays.tscn','FRESH MARKET',[x[0] for x in grocery]+['bread'],14,15,existing=True)
# Apparel store retains its shell and fitting rooms; reauthor interior to remove
# tiny generic boxes and ensure each garment is a coherent editable object.
cl=ROOT/'scenes/buildings/clothing_store.tscn'
ct=cl.read_text(); roots=list(re.finditer(r'\[node name="([^\"]+)"[^\n]*parent="\."[^\n]*\]\n',ct))
room('clothing_displays.tscn','CLOTHING',[x[0] for x in clothes],10.8,15.2,existing=True)
# Keep the apparel exterior, lighting and doorway, replace the old interior.
marker='[node name="ClothingRack"'
if marker in ct: ct=ct[:ct.index(marker)]
if 'id="learning_display"' not in ct:
    idx=ct.index('[sub_resource')
    ct=ct[:idx]+'[ext_resource type="PackedScene" path="res://scenes/buildings/clothing_displays.tscn" id="learning_display"]\n\n'+ct[idx:]
    ct+='\n[node name="LearningDisplays" parent="." instance=ExtResource("learning_display")]\n'
cl.write_text(ct)
# Canonical vocabulary is shared by popup, journal and mission system.
data=word_data.load()
for k in DEPRECATED_WORDS:data['words'].pop(k,None)
for k,v in CATALOG.items():
    entry=data['words'].setdefault(k,{'spanish':v['spanish'],'category':v['category']})
    entry['prefab_size']=v['size']
word_data.save(data)
print('Authored',len(CATALOG),'reusable vocabulary scenes')
