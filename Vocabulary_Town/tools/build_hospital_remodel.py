"""Hospital remodel authoring. Called by build_hospital_floors.py; school is untouched."""
from pathlib import Path
import math
from scene_writer import Scene, v
ROOT=Path(__file__).resolve().parents[1]
H=5.6
# Interior palette (27 Oct 2026). FLOOR_TINTS identify each storey (hall stripe,
# runner, stairs, elevator, floor signs); ROOM_TINTS give every room its own colour
# (door header, sign, floor inset, feature wall). The facade header panels above the
# entrance bay are wall-coloured since 31 Oct 2026 (the user removed the colour bars).
# Keep FLOOR_TINTS in sync with hospital_elevator.gd.
FLOOR_TINTS=['2a9d8f','3d7fc1','e38b3c']
# Roof access (31 Oct 2026): the stairs and elevator continue to the roof (AZOTEA), whose
# walking surface is the top of the roof slabs (Azotea/TopSlab). The roof stop has its own identity colour.
ROOF_Y=16.925; ROOF_TINT='6d8f9c'; TINTS=FLOOR_TINTS+[ROOF_TINT]
# The elevator sits in a tower outside the right wall (x=-9); its doors open at x=-9.
LIFT_X=-11.6; LIFT_TOP=5.0
PHARMACY='2e9e5b'
ROOM_TINTS=[['f2b84b','d9534f','4fa3d1','7bbf6a'],['f29e7b','9b7fd1','3fb3a8','5a8fd6'],['7a6fd1','52b788','f4a259','c77dba']]
# One room deeper since 27 Oct 2026: front rooms, stair/elevator core, open lounge
# (z 4.5..12.2), back rooms (z 12.2..19.9). REAR is the rear facade line.
REAR=19.9; BACK_Z=16.05
WALL='f4f1ea'; FLOOR='e6e2da'; OAK='dcc7a1'; RAIL='a8774e'; STEEL='a7b1b4'
def tint(c,amount):
    """Mix hex colour c toward white by amount (0 = c, 1 = white)."""
    rgb=[int(c[i:i+2],16) for i in (0,2,4)]
    return ''.join(f'{round(v+(255-v)*amount):02x}' for v in rgb)
# Wall skins (31 Oct 2026, user request): every room's inner walls show its soft theme
# colour (the feature wall's tint(room,.62)); halls, lounges, the lift lobby and the
# upper annex show WALL. Skins are thin non-solid panels 1 cm proud of the inner face,
# so the facade, hall faces and collisions are unchanged.
def skin(s,parent,c,axis,face,lo,hi,parts):
    """Skin the solid parts (a0,a1,y0,y1) of a wall running along z (axis 'x', at x=face)
    or along x (axis 'z', at z=face), clipped to lo..hi along the wall."""
    for a0,a1,y0,y1 in parts:
        a0,a1,y0,y1=max(a0,lo),min(a1,hi),max(y0,.05),min(y1,5.35)
        if a1-a0<.02 or y1<=y0:continue
        if axis=='x':s.box('WallSkin',(face,(y0+y1)/2,(a0+a1)/2),(.02,y1-y0,a1-a0),c,parent)
        else:s.box('WallSkin',((a0+a1)/2,(y0+y1)/2,face),(a1-a0,y1-y0,.02),c,parent)
def window_wall(c0,length,sill,piers):
    """Solid parts of a window wall: sill up to `sill`, lintel from 3.9, and piers."""
    return [(c0-length/2,c0+length/2,0,sill),(c0-length/2,c0+length/2,3.9,5.4)]+[(a0,a1,sill,3.9) for a0,a1 in piers]
def skin_room(s,f,x,z,side,front,c):
    """A corner room's inner faces: partitions and door header (x=±2), the side window
    wall (x=±9) and the facade window wall. The cross wall carries the feature wall."""
    zlo,zhi=sorted((z-front*3.78,z+front*3.75)); xlo,xhi=sorted((side*2.07,side*8.91))
    skin(s,f,c,'x',side*2.08,zlo,zhi,[(z-3.85,z-1.65,0,5.4),(z+1.65,z+3.85,0,5.4),(z-1.65,z+1.65,3.4,5.4)])
    skin(s,f,c,'x',side*8.9,zlo,zhi,window_wall(z,7.7,1.4,[(z-3.85,z-2.6),(z+2.6,z+3.85)]))
    fx=side*5.4
    skin(s,f,c,'z',z+front*3.75,xlo,xhi,window_wall(fx,7.2,1.3,[(fx-3.6,fx-2.4),(fx+2.4,fx+3.6)]))
def skin_shared(s,f,level):
    """Shared areas in WALL; on floor 1 the annex behind the stair-side wall (z>4.6) is
    the pharmacy and takes its colour."""
    skin(s,f,WALL,'x',-8.9,4.5,12.13,window_wall(8.35,7.7,1.4,[(4.5,5.75),(10.95,12.2)]))
    skin(s,f,WALL,'x',-8.9,-4.43,4.5,[(-4.5,-2.6,0,5.4),(2.6,4.5,0,5.4)])
    skin(s,f,WALL,'z',REAR-.1,-1.8,1.8,[(-1.8,1.8,0,3.8)])
    if level:skin(s,f,WALL,'z',-12.1,-1.8,1.8,[(-1.8,1.8,0,3.8)])
    annex=window_wall(5,14,1.3,[(-2,0),(4,6),(10,12)])
    pharmacy=tint(PHARMACY,.6)
    for lo,hi,c in ([(-1.91,4.53,WALL),(4.67,11.91,pharmacy)] if level==0 else [(-1.91,11.91,WALL)]):
        skin(s,f,c,'x',15.9,lo,hi,annex)
    skin(s,f,WALL,'z',-1.9,9,15.91,[(9,16,0,5.4)])
    skin(s,f,pharmacy if level==0 else WALL,'z',11.9,9,15.91,[(9,16,0,5.4)])
    if level==0:
        skin(s,f,pharmacy,'z',4.68,2.07,15.91,[(2,16,0,5.4)])
        skin(s,f,pharmacy,'x',2.08,4.67,12.13,[(4.5,5.1,0,5.4),(5.1,12.2,3.0,5.4),(6.9,12.2,0,.45)])
def tiled(s,name,p,size,c,parent,solid=False):
    """Floor surface in colour c with the hospital tile shader (60 cm tiles, grout, speckle)."""
    i=len(s.nodes); path=s.box(name,p,size,c,parent,solid)
    rgb=', '.join(str(int(c[k:k+2],16)/255) for k in (0,2,4))
    mat=s.res('ShaderMaterial','shader = '+s.external('res://shaders/hospital_floor.gdshader','Shader')+f'\nshader_parameter/base_color = Color({rgb}, 1)')
    s.nodes[i]=s.nodes[i].replace('material_override = '+s.mat(c),'material_override = '+mat)
    return path
def side_sign(s,name,lines,p,width,height,parent,color,yaw,solid=False):
    """Panel facing along X (yaw -pi/2 faces -X, pi/2 faces +X) with stacked labels."""
    s.box(name+'Panel',p,(.09,height,width),color,parent,solid)
    out=-.06 if yaw<0 else .06
    for i,(text,size,dy) in enumerate(lines):
        s.node(name+str(i),'Label3D',parent,'position = '+v((p[0]+out,p[1]+dy,p[2]))+f'\nrotation = Vector3(0, {yaw}, 0)\ntext = "{text}"\nfont_size = {size}\npixel_size = 0.008\noutline_size = 6')

def furnish(s, room, level, idx, accent):
    if level==0 and idx==0:
        # Reception (27 Oct 2026): a counter with a tall wood front and visitor ledge, a
        # lower worktop and return behind it, pendant lights, a wood-slat feature wall with
        # the hospital cross and one sign. The BonBon-sized sheep doctor stands at (-.35,0,2.75);
        # the ledge is at its chest (0.95, lowered from 1.27 on 31 Oct 2026).
        s.box('ReceptionCounter',(0,.46,1.45),(3.5,.92,.24),'c4956a',room,True)
        s.box('DeskAccentStripe',(0,.74,1.325),(3.5,.1,.02),accent,room)
        s.box('DeskKick',(0,.08,1.325),(3.5,.16,.02),'6b5a4a',room)
        s.box('DeskLedge',(0,.95,1.42),(3.7,.06,.42),'f4efe4',room)
        s.box('DeskWorktop',(0,.7,1.9),(3.3,.06,.7),'f4efe4',room)
        s.box('ReceptionReturn',(-1.6,.35,2.45),(.6,.7,1.3),'c4956a',room,True)
        s.box('ReturnTop',(-1.6,.725,2.45),(.7,.05,1.4),'f4efe4',room)
        turned_prop(s,'computer',(.5,.73,1.95),room,math.pi,.5)
        for x in [-1,0,1]:
            s.box('PendantRod',(x,4.65,1.9),(.02,1.1,.02),STEEL,room)
            s.orb('PendantShade',(x,4.0,1.9),(.5,.3,.5),'fbe7b3',room)
        for i in range(9):s.box('WallSlat',(-2+i*.5,2.0,3.72),(.2,2.4,.04),'c99a6b',room)
        s.box('ReceptionLogo',(0,2.45,3.69),(1.2,1.2,.03),'fbf8f2',room)
        for size in [(.3,.85,.02),(.85,.3,.02)]:s.box('ReceptionCross',(0,2.45,3.665),size,'d9534f',room)
        s.box('ReceptionSignPanel',(0,3.95,3.7),(3.6,.95,.06),accent,room)
        s.text('ReceptionSign','RECEPCIÓN',(0,4.08,3.66),room,size=44)
        s.text('ReceptionWelcome','BIENVENIDOS',(0,3.68,3.66),room,size=26)
        for i in range(4):s.prop('chair',(-1.8+i*1.2,0,-2.8),room,.85)
        s.box('WaitingRug',(0,.045,-3),(5.6,.02,2.4),tint(accent,.45),room)
        s.plant((2.1,0,3.3),room)
        s.plant((-2.6,0,3.3),room)
        s.box('TicketDispenser',(2.1,1.1,-1),(.4,.5,.35),accent,room)
        s.box('TicketPost',(2.1,.5,-1),(.1,1,.1),STEEL,room)
    elif (level==1 and idx==0):
        s.box('PlayMat',(0,.04,0),(3.3,.04,3.3),'cfb77c',room)
        for i,c in enumerate(['e1a085','81b5c3','b6c28b']):s.box('ToyBlock'+str(i),(-1+i,.4,1),(.65,.7,.65),c,room,True)
        s.prop('chair',(-1,0,-2.6),room)
        for dx,c in [(-.8,'8cb7bc'),(.8,'dda88e')]:
            s.box('ChildStool',(dx,.28,1.8),(.55,.55,.55),c,room,True)
        s.text('AlphabetMural','A B C   ·   1 2 3',(0,2.8,3.55),room,size=46)
        for i,c in enumerate(['e0a58b','e5c87b','93b6a3','87aabe']):
            s.box('MuralStripe',(-1.2+i*.8,1.75,3.59),(.65,.16,.025),c,room)
        s.plant((2.1,0,3.3),room)
        s.prop('book',(0,.8,2.8),room,.8)
        s.box('ReadingTable',(0,.65,2.8),(2,.3,1),'d1b690',room,True)
        for dx in [-.8,.8]:
            for dz in [2.5,3.1]:s.box('TableLeg',(dx,.25,dz),(.12,.5,.12),'a78c69',room)
    elif level==2 and idx in [1,3]:
        s.prop('walker',(-1,0,1),room)
        s.prop('crutches',(1,0,2.5),room)
        s.prop('wheelchair',(-1,0,-2),room)
        for dx in [-1,1]:
            s.box('TherapyRail'+str(dx),(dx,1.1,0),(.08,.1,3),'8b9f9b',room)
            for dz in [-1.4,1.4]:s.box('TherapyPost',(dx,.55,dz),(.07,1.1,.07),'8b9f9b',room)
        s.box('TherapyMat',(0,.045,0),(2.5,.02,3.3),'c3b0c4',room)
        for dz in [-1,0,1]:
            s.box('GaitMarker',(.22,.065,dz),(.25,.015,.4),'ede6d9',room)
            s.box('GaitMarker',(-.22,.065,dz+.45),(.25,.015,.4),'ede6d9',room)
        s.plant((2.1,0,3.3),room)
    else:
        s.node('HospitalBed',parent=room,props='position = Vector3(0,0,1)',instance=s.external('res://scenes/props/furniture/hospital_bed.tscn'))
        s.prop('medical_monitor',(-1.9,1.0,2.7),room,.8)
        s.box('MonitorStand',(-1.9,.5,2.7),(.8,1,.7),'dfe6e8',room,True)
        s.prop('iv_stand',(1.6,0,2.5),room,.85)
        s.prop('chair',(-1.2,0,-2.5),room,.85)
        s.box('BedsideCabinet',(1.8,.55,.4),(.9,1.1,.7),'cbb695',room,True)
        for dy in [.35,.75]:
            s.box('DrawerFront',(1.8,dy,.025),(.78,.3,.04),'e8ddc6',room)
            s.box('DrawerHandle',(1.8,dy,-.01),(.28,.035,.05),'718884',room)
        s.box('Headwall',(0,1.65,3.6),(3.3,.45,.07),accent,room)
        for dx in [-.7,0,.7]:s.orb('MedicalOutlet',(dx,1.65,3.54),(.12,.12,.04),'f5f0e1',room)
        if level==2:s.plant((2.1,0,3.3),room)
    if (level==0 and idx==1) or (level==1 and idx==1):
        s.box('ExamCounter',(1.8,.85,-2.5),(1.2,1.7,1.5),'dfe6e8',room,True)
        s.prop('stethoscope',(1.8,1.7,-2.9),room,.65)
        s.prop('thermometer',(1.8,1.7,-2.2),room,.65)

# The former single-storey rear wing (removed 27 Oct 2026) duplicated four main-floor
# programs. Its displays now live in the matching rooms; room-local positions avoid
# each room's bed, counters, cabinet and door (doorway |z|<1.65 at local x=-3.5).
def waiting_room(s,room,accent):
    """Welcoming waiting room (31 Oct 2026, user request; the nurse who stood here is gone).
    Room-local: the hall door is at x=-3.5 (|z|<1.65, kept clear), the feature wall at
    z=-3.85 and the facade window at z=+3.85. Two sofas face each other over a rug and a
    coffee table, with an armchair, a lamp, framed pictures, an aquarium, a kids' corner,
    plants and a warm light."""
    s.box('WaitingRug',(.7,.04,0),(4.4,.02,4.6),tint(accent,.35),room)
    s.box('RugBorder',(.7,.035,0),(4.7,.02,4.9),tint(accent,.1),room)
    turned_prop(s,'sofa',(.7,0,-3.05),room,math.pi,.95)
    turned_prop(s,'sofa',(.7,0,3.05),room,0,.95)
    turned_prop(s,'armchair',(3,0,0),room,1.5708)
    turned_prop(s,'coffee_table',(.7,0,0),room,0)
    s.prop('book',(.4,.5,0),room,.5)
    s.box('MagazineStack',(1.15,.5,.1),(.45,.06,.32),'e9a77b',room)
    s.box('MagazineStack',(1.15,.54,.08),(.42,.03,.3),'7fb3c9',room)
    turned_prop(s,'lamp',(3.05,0,-3.2),room,0,.85)
    s.plant((3.05,0,3.25),room)
    s.plant((-2.95,0,-2.2),room)
    # Framed pictures over the feature-wall sofa: a sunny landscape, a flower and a boat.
    for x,(back,shape) in zip([-.9,.7,2.3],[('9fd0e4','8bbf6a'),('f6e1b5','e58b8b'),('bfe0ee','4f8fc7')]):
        s.box('PictureFrame',(x,2.25,-3.74),(1.1,.85,.05),'c99a6b',room)
        s.box('PictureCanvas',(x,2.25,-3.71),(.94,.69,.02),back,room)
        s.orb('PictureMotif',(x,2.12,-3.695),(.5,.28,.02),shape,room)
    # Aquarium on a low cabinet in the corner by the door, clear of the doorway.
    s.box('AquariumCabinet',(-2.65,.4,-3.3),(1.3,.8,.6),'c4956a',room,True)
    s.box('AquariumWater',(-2.65,1.13,-3.3),(1.2,.62,.5),'8fd1e0',room)
    s.box('AquariumGlass',(-2.65,1.15,-3.3),(1.26,.7,.56),'ffffff',room,glass=True)
    s.box('AquariumSand',(-2.65,.84,-3.3),(1.18,.06,.48),'e8d3a0',room)
    for i,(dx,dy,c) in enumerate([(-.3,1.2,'f29e4c'),(.15,1.05,'f2c94c'),(.35,1.28,'e56b6f')]):
        s.orb('AquariumFish',(-2.65+dx,dy,-3.52),(.16,.09,.04),c,room)
    for dx in [-.45,.4]:s.orb('AquariumWeed',(-2.65+dx,1.0,-3.25),(.08,.3,.08),'5fae6e',room)
    # Kids' corner by the window: a soft mat, toy blocks and a ball.
    s.box('KidsMat',(-2.3,.035,2.85),(1.9,.03,1.6),'f6d58e',room)
    for i,(dx,dz,c) in enumerate([(-.5,.2,'e1a085'),(0,.35,'81b5c3'),(-.25,.3,'b6c28b')]):
        s.box('ToyBlock',(-2.3+dx,.2+(.33 if i==2 else 0),2.85+dz),(.32,.32,.32),c,room)
    s.prop('soccer_ball',(-1.8,.04,2.55),room,.35)
    s.node('WaitingLight','OmniLight3D',room,'position = '+v((.7,3.4,0))+'\nlight_color = Color(1, 0.92, 0.8, 1)\nlight_energy = 0.6\nomni_range = 6')

# Anatomy teaching model (31 Oct 2026, user request): a friendly child figure in the
# floor-2 lounge, replacing the old outdoor display. Its left half (seen from the front)
# has skin, hair and a smile; its right half is a soft cut-away showing pastel organs on
# a pink lining, a peek of brain under the hair and one simple bone in the leg. No skull
# or veins, so it teaches without scaring. Model space faces -Z, +X is the skin side.
# Every taught part is its own word root with a non-solid pick area, so small parts in
# front (eyes, teeth, fingers, toes, knees) win the click; only the plinth is solid.
SKIN='f2c4a0'
def anat(s,kind,name,p,size,c,parent,rot=None):
    """Smooth ball (size = scale), pill (size = radius, height) or disc mesh."""
    if kind=='ball':
        mesh=s.res('SphereMesh','radius = 0.5\nheight = 1.0\nradial_segments = 20\nrings = 10'); extra='\nscale = '+v(size)
    elif kind=='pill':
        mesh=s.res('CapsuleMesh',f'radius = {size[0]}\nheight = {size[1]}\nradial_segments = 16\nrings = 4'); extra=''
    else:
        mesh=s.res('CylinderMesh',f'top_radius = {size[0]}\nbottom_radius = {size[0]}\nheight = {size[1]}\nradial_segments = 28'); extra=''
    s.node(name,'MeshInstance3D',parent,'position = '+v(p)+extra+'\nmesh = '+mesh+'\nmaterial_override = '+s.mat(c)+(f'\nrotation = {v(rot)}' if rot else ''))
def anat_part(s,model,key,picks):
    """Word root for one body part; picks are (centre, size) boxes for its pick area."""
    root=s.node(''.join(w.title() for w in key.split()),parent=model,props=f'metadata/word_key = "{key}"')
    area=s.node('Pick','Area3D',root,'monitoring = false\nmonitorable = false')
    for c,size in picks:s.node('Shape','CollisionShape3D',area,'position = '+v(c)+'\nshape = '+s.res('BoxShape3D','size = '+v(size)))
    return root
def anatomy_model(s,parent,p):
    m=s.node('AnatomyModel',parent=parent,props='position = '+v(p)+'\nscale = Vector3(0.95, 0.95, 0.95)')
    anat(s,'disc','Plinth',(0,.1,0),(.62,.2),'cfe3e0',m)
    anat(s,'disc','PlinthRim',(0,.205,0),(.64,.02),'7fb8b0',m)
    body=s.node('PlinthBody','StaticBody3D',m)
    s.node('Shape','CollisionShape3D',body,'position = Vector3(0, 0.1, 0)\nshape = '+s.res('CylinderShape3D','height = 0.2\nradius = 0.62'))
    s.text('PlinthSign','EL CUERPO HUMANO',(0,.1,-.63),m,size=20)
    anat(s,'ball','Shorts',(0,.98,0),(.58,.3,.4),'4f7fc4',m)
    s.box('ShortsStripe',(0,.88,-.17),(.5,.03,.04),'eef2f6',m)
    # Legs and knees: the open (-X) leg shows a muscle band with one cream bone.
    r=anat_part(s,m,'leg',[((.16,.62,0),(.22,.66,.22)),((-.16,.62,0),(.22,.66,.22))])
    for x in [.16,-.16]:anat(s,'pill','Leg',(x,.62,0),(.105,.7),SKIN,r)
    anat(s,'pill','LegMuscle',(-.16,.62,-.075),(.075,.6),'ec9a9a',r)
    anat(s,'pill','LegBone',(-.16,.62,-.13),(.03,.52),'f5ecd7',r)
    r=anat_part(s,m,'knee',[((.16,.62,-.11),(.16,.13,.06)),((-.16,.62,-.15),(.14,.12,.05))])
    anat(s,'ball','Knee',(.16,.62,-.085),(.15,.11,.07),'efb994',r)
    anat(s,'ball','KneeBone',(-.16,.62,-.135),(.09,.08,.05),'f5ecd7',r)
    r=anat_part(s,m,'foot',[((.16,.27,-.04),(.22,.14,.3)),((-.16,.27,-.04),(.22,.14,.3))])
    for x in [.16,-.16]:anat(s,'ball','Foot',(x,.27,-.05),(.2,.13,.32),SKIN,r)
    r=anat_part(s,m,'toe',[((.16,.27,-.215),(.22,.08,.06)),((-.16,.27,-.215),(.22,.08,.06))])
    for x in [.16,-.16]:
        for i in range(5):anat(s,'ball','Toe',(x+(i-2)*.038*(1 if x>0 else -1),.255+(.008 if i in [1,2,3] else 0),-.195),(.04,.04,.04) if i else (.05,.05,.05),SKIN,r)
    # Torso: chest and belly bumps on the skin side, the back is the torso itself.
    r=anat_part(s,m,'back',[((0,1.32,.1),(.6,.7,.22))])
    anat(s,'ball','Torso',(0,1.32,0),(.6,.72,.42),SKIN,r)
    r=anat_part(s,m,'chest',[((.15,1.48,-.2),(.28,.24,.06))])
    anat(s,'ball','Chest',(.15,1.49,-.18),(.3,.2,.04),'f3c7a5',r)
    r=anat_part(s,m,'belly',[((.13,1.15,-.205),(.28,.26,.06))])
    anat(s,'ball','Belly',(.13,1.15,-.175),(.3,.26,.07),'f3c7a5',r)
    anat(s,'ball','BellyButton',(.13,1.12,-.222),(.025,.025,.01),'c98d6e',r)
    # The cut-away window: lining, then organs in front of it.
    anat(s,'ball','CutRim',(-.12,1.32,-.18),(.37,.66,.06),'e98f8f',m)
    anat(s,'ball','CutLining',(-.12,1.32,-.19),(.33,.6,.06),'f8c4c0',m)
    anat(s,'pill','Windpipe',(-.12,1.62,-.215),(.022,.14),'a9d3e8',m)
    r=anat_part(s,m,'lungs',[((-.22,1.47,-.245),(.13,.23,.04)),((-.02,1.47,-.245),(.13,.23,.04))])
    for x in [-.22,-.02]:anat(s,'ball','Lung',(x,1.47,-.225),(.13,.23,.06),'f0939f',r)
    r=anat_part(s,m,'heart',[((-.1,1.43,-.262),(.1,.1,.03))])
    anat(s,'ball','Heart',(-.1,1.43,-.245),(.1,.11,.06),'e0505f',r)
    r=anat_part(s,m,'liver',[((-.18,1.285,-.255),(.19,.09,.03))])
    anat(s,'ball','Liver',(-.18,1.285,-.232),(.2,.1,.06),'b8644f',r)
    r=anat_part(s,m,'stomach',[((-.02,1.27,-.26),(.12,.1,.03))])
    anat(s,'ball','Stomach',(-.02,1.27,-.237),(.13,.11,.06),'f5c26b',r)
    r=anat_part(s,m,'large intestine',[((-.25,1.1,-.25),(.06,.22,.03)),((-.12,1.2,-.25),(.3,.06,.03)),((.01,1.1,-.25),(.06,.22,.03))])
    anat(s,'pill','LargeIntestine',(-.25,1.1,-.228),(.03,.22),'c98bb0',r)
    anat(s,'pill','LargeIntestine',(-.12,1.2,-.228),(.03,.3),'c98bb0',r,(0,0,1.5708))
    anat(s,'pill','LargeIntestine',(.01,1.1,-.228),(.03,.22),'c98bb0',r)
    r=anat_part(s,m,'small intestine',[((-.12,1.09,-.262),(.2,.13,.03))])
    for dx,dy in [(-.06,1.12),(0,1.125),(.06,1.12),(-.07,1.06),(0,1.06),(.07,1.065)]:
        anat(s,'ball','SmallIntestine',(-.12+dx,dy,-.24),(.07,.065,.05),'f6b48f',r)
    # Neck, shoulders, arms, hands and fingers (palms forward like the reference).
    r=anat_part(s,m,'neck',[((0,1.74,0),(.18,.14,.18))])
    anat(s,'pill','Neck',(0,1.74,0),(.09,.22),SKIN,r)
    r=anat_part(s,m,'shoulder',[((.33,1.61,0),(.2,.16,.22)),((-.33,1.61,0),(.2,.16,.22))])
    for x in [.33,-.33]:anat(s,'ball','Shoulder',(x,1.6,0),(.2,.18,.2),SKIN,r)
    r=anat_part(s,m,'arm',[((.49,1.37,0),(.16,.36,.15)),((-.49,1.37,0),(.16,.36,.15))])
    for sx in [1,-1]:anat(s,'pill','Arm',(sx*.48,1.38,0),(.07,.55),SKIN,r,(0,0,sx*.54))
    r=anat_part(s,m,'hand',[((.63,1.13,0),(.14,.13,.1)),((-.63,1.13,0),(.14,.13,.1))])
    for sx in [1,-1]:anat(s,'ball','Hand',(sx*.63,1.13,0),(.15,.14,.09),SKIN,r)
    r=anat_part(s,m,'finger',[((.64,1.03,-.01),(.15,.08,.07)),((-.64,1.03,-.01),(.15,.08,.07))])
    for sx in [1,-1]:
        for i in range(4):anat(s,'pill','Finger',(sx*(.585+i*.035),1.035+(.005 if i in [1,2] else 0),0),(.018,.08),SKIN,r,(0,0,sx*(.15+i*.08)))
        anat(s,'pill','Thumb',(sx*.565,1.12,-.035),(.02,.08),SKIN,r,(.6,0,-sx*.7))
    # Head: big and round, a smiling face, hair on the skin side and the brain beside it.
    r=anat_part(s,m,'head',[((0,2.1,.05),(.6,.55,.48))])
    anat(s,'ball','Head',(0,2.08,0),(.62,.58,.56),SKIN,r)
    r=anat_part(s,m,'face',[((0,2.02,-.265),(.44,.36,.04))])
    anat(s,'ball','Face',(0,2.03,-.215),(.46,.4,.12),'f5cbaa',r)
    r=anat_part(s,m,'hair',[((.1,2.27,.02),(.42,.18,.58)),((.1,2.2,-.255),(.26,.08,.05))])
    anat(s,'ball','Hair',(.08,2.25,.03),(.52,.34,.6),'7a4b2e',r)
    anat(s,'ball','HairFringe',(.1,2.21,-.235),(.28,.1,.1),'7a4b2e',r,(0,0,-.25))
    r=anat_part(s,m,'brain',[((-.15,2.3,-.04),(.26,.16,.34))])
    anat(s,'ball','Brain',(-.14,2.28,-.04),(.3,.22,.38),'f3a5b8',r)
    for dz in [-.1,.02]:anat(s,'pill','BrainFold',(-.14,2.36,dz),(.012,.22),'df8ea3',r,(0,0,1.5708))
    r=anat_part(s,m,'ear',[((.31,2.06,0),(.08,.13,.1)),((-.31,2.06,0),(.08,.13,.1))])
    for sx in [1,-1]:
        anat(s,'ball','Ear',(sx*.31,2.06,0),(.08,.13,.1),SKIN,r)
        anat(s,'ball','EarInner',(sx*.335,2.06,-.005),(.03,.08,.05),'e8a88a',r)
    r=anat_part(s,m,'eye',[((.1,2.08,-.3),(.12,.13,.04)),((-.1,2.08,-.3),(.12,.13,.04))])
    for sx in [1,-1]:
        anat(s,'ball','EyeWhite',(sx*.1,2.08,-.278),(.11,.12,.04),'ffffff',r)
        anat(s,'ball','Pupil',(sx*.1,2.075,-.293),(.075,.085,.03),'4a3426',r)
        anat(s,'ball','EyeShine',(sx*.1+.018,2.095,-.305),(.022,.022,.01),'ffffff',r)
    r=anat_part(s,m,'nose',[((0,2.0,-.31),(.07,.06,.04))])
    anat(s,'ball','Nose',(0,2.0,-.29),(.065,.05,.05),'eeb48f',r)
    r=anat_part(s,m,'mouth',[((0,1.925,-.295),(.2,.09,.03))])
    anat(s,'ball','Mouth',(0,1.925,-.272),(.15,.075,.03),'a8424e',r)
    r=anat_part(s,m,'tooth',[((0,1.948,-.312),(.09,.03,.02))])
    s.box('Teeth',(0,1.948,-.284),(.09,.022,.012),'fffaf0',r)
    r=anat_part(s,m,'tongue',[((0,1.903,-.312),(.07,.035,.02))])
    anat(s,'ball','Tongue',(0,1.905,-.283),(.07,.032,.015),'f08a96',r)
    for sx in [1,-1]:anat(s,'ball','Cheek',(sx*.17,1.98,-.255),(.08,.05,.02),'f4a3a3',m)

def turned_prop(s,key,p,parent,yaw,scale=1):
    """Vocabulary prop rotated about Y; seating props face -Z at yaw 0."""
    path='res://scenes/props/vocabulary/'+key+'.tscn'
    s.node(key.title().replace('_',''),parent=parent,props='position = '+v(p)+f'\nrotation = Vector3(0, {yaw}, 0)\nscale = '+v((scale,)*3),instance=s.external(path))

def lounge(s,f,level):
    """Open lounge behind the stairs/elevator: a seating group either side of the hall.
    On floor 1 the stair side is the pharmacy (31 Oct 2026)."""
    for side in ([-1] if level==0 else [-1,1]):
        cx=side*5.6
        # Floor 2's stair-side group sits in the open annex corner (31 Oct 2026, user
        # request) with the sofa against the annex rear wall; the anatomy model takes its
        # old place against the back-room wall. The gallery route (z<5) stays clear.
        gx,gz=(12.5,8.15) if (level,side)==(1,1) else (cx,8.4)
        s.box('LoungeRug',(gx,.03,gz),(5.4,.02,5.2),tint(FLOOR_TINTS[level],.55),f)
        turned_prop(s,'sofa',(gx,0,gz+2.5),f,0)
        turned_prop(s,'coffee_table',(gx,0,gz+.7),f,0)
        turned_prop(s,'armchair',(gx-2,0,gz+.2),f,-1.5708)
        turned_prop(s,'armchair',(gx+2,0,gz+.2),f,1.5708)
        turned_prop(s,'lamp',(15.3,0,11.4) if (level,side)==(1,1) else (side*8.3,0,11.5),f,0,.9)
        s.plant((side*8.3,0,5.2),f)
        s.box('LoungeLightPanel',(gx,5.25,gz-.05),(2.5,.07,1),'fff4d9',f)
        s.node('LoungeLight','OmniLight3D',f,'position = '+v((gx,4,gz-.05))+'\nlight_energy = 0.85\nomni_range = 9')

def former_wing_displays(s,room,level,idx):
    if level==0 and idx==1:  # Urgencias
        s.prop('stretcher',(2.95,0,.3),room,.9)
        s.prop('defibrillator',(.2,0,-3.3),room,.85)
        s.prop('oxygen_tank',(-3,0,2.7),room,.85)
        s.prop('first_aid_kit',(-3,0,-2.9),room,.85)
        s.prop('syringe',(1.45,1.7,-2.55),room,.6)
        s.prop('surgical_mask',(1.8,1.1,.4),room,.6)
    elif level==0 and idx==2:  # Exámenes
        s.prop('blood_pressure_monitor',(1.8,1.1,.4),room,.7)
        s.prop('reflex_hammer',(1.45,1.7,-2.55),room,.6)
        s.prop('medicine',(2.15,1.7,-2.55),room,.6)
    elif level==2 and idx==0:  # Imágenes
        s.prop('MRI_scanner',(1.9,0,-1.9),room,.8)
        s.box('SupplyTable',(-2.6,.45,2.8),(.9,.9,1.5),'dfe6e8',room,True)
        s.prop('computer',(-2.65,.9,2.4),room,.55)
        s.prop('clipboard',(-2.6,.9,2.95),room,.5)
        s.prop('headphones',(-2.6,.9,3.3),room,.5)
    elif level==2 and idx==2:  # Fisioterapia
        s.prop('prosthetic_leg',(2.8,0,-2.6),room,.8)
        s.box('SupplyTable',(-2.6,.45,-2.9),(.9,.9,.7),'dfe6e8',room,True)
        s.prop('bandage',(-2.8,.9,-2.9),room,.6)
        s.prop('medicine',(-2.35,.9,-2.9),room,.6)

def hinge_door(s,name,parent,p,width,height,angle,color,glass=False,along_x=False,reverse=False):
    """Door leaf running +Z (or +X; -Z/-X when reverse) from its hinge at p. Main registers
    door_state on load and swings it with E or a click: a positive angle turns +Z toward +X
    and +X toward -Z (so -X toward +Z)."""
    pivot=s.node(name,parent=parent,props='position = '+v(p)+'\nmetadata/word_key = "door"\nmetadata/door_state = {"open": false, "type": "hinge", "angle": '+str(angle)+'}')
    def put(part,u,y,across,du,dy,thick,c,**kw):
        # u runs along the leaf from the hinge; across is through the door.
        if reverse:u=-u
        s.box(part,(u,y,across) if along_x else (across,y,u),(du,dy,thick) if along_x else (thick,dy,du),c,pivot,**kw)
    put('DoorCollision',width/2,height/2,0,width,height,.1,'789993',solid=True,visible=False)
    if glass:
        for u in [.05,width-.05]:put('DoorStile',u,height/2,0,.1,height,.09,color)
        for y,h in [(.1,.2),(height-.06,.12)]:put('DoorRail',width/2,y,0,width,h,.09,color)
        put('DoorGlass',width/2,height/2+.04,0,width-.2,height-.32,.04,color,glass=True)
    else:
        put('DoorLeaf',width/2,height/2,0,width,height,.08,color)
        put('DoorKick',width/2,.12,0,width-.1,.2,.1,STEEL)
    for a in [-.09,.09]:put('DoorHandle',width-.25,1.1,a,.05,.5 if glass else .12,.04,STEEL)

def pharmacy(s,f):
    """Floor 1 pharmacy (31 Oct 2026): the stair-side lounge plus the annex behind it,
    entered through a glass shopfront and door on the hall (x=2). The dispensing counter
    stands before the Emergency wall; the annex keeps the medicine shelf, trolley and
    display cluster that world_refinements.gd moves there, and the FARMACIA plaque."""
    p=s.node('Pharmacy',parent=f)
    # Enclosure: shopfront on the hall; one wall along the stair approach (z=4.6).
    s.box('ShopfrontPier',(2,2.7,4.8),(.14,5.4,.6),WALL,p,True)
    s.box('ShopfrontHeader',(2,4.2,8.65),(.14,2.4,7.1),WALL,p,True)
    s.box('ShopfrontSill',(2,.225,9.55),(.14,.45,5.3),WALL,p,True)
    s.box('ShopfrontGlass',(2,1.725,9.55),(.06,2.55,5.3),'',p,True,glass=True)
    for z in [6.95,8.7,10.45,12.15]:s.box('ShopfrontMullion',(2,1.7,z),(.12,2.6,.1),'6c8989',p)
    s.box('ShopfrontFrame',(2,3.0,8.65),(.12,.1,7.1),'6c8989',p)
    s.box('ShopfrontFrame',(2,.47,9.55),(.12,.06,5.3),'6c8989',p)
    s.box('StairSideWall',(9,2.7,4.6),(14.14,5.4,.14),WALL,p,True)
    hinge_door(s,'PharmacyDoor',p,(2,0,5.1),1.8,2.95,1.7,'6c8989',True)
    # Hall face: green cross by the door and the FARMACIA sign over the glass.
    for size in [(.06,.7,.22),(.06,.22,.7)]:s.box('PharmacyCross',(1.89,4.2,6.0),size,'3cc46a',p)
    side_sign(s,'PharmacySign',[('FARMACIA',60,0)],(1.88,4.2,9.4),4.6,.9,p,PHARMACY,-1.5708)
    s.box('PharmacyFloor',(5.55,.02,8.4),(6.9,.02,7.3),tint(PHARMACY,.8),p)
    s.box('PharmacyFloor',(12.5,.02,8.3),(6.8,.02,7.1),tint(PHARMACY,.8),p)
    s.box('FeatureWall',(5.55,2.7,12.11),(6.9,5.3,.02),tint(PHARMACY,.6),p)
    # Dispensing counter facing the shop; staff pass at either end.
    s.box('PharmacyCounter',(5.7,.55,10.3),(5,1.1,.6),'f4f1ea',p,True)
    s.box('CounterStripe',(5.7,.85,9.99),(5,.12,.02),PHARMACY,p)
    s.box('CounterKick',(5.7,.08,9.99),(5,.16,.02),'6b5a4a',p)
    s.box('CounterTop',(5.7,1.13,10.25),(5.2,.06,.8),'e9e4d8',p)
    turned_prop(s,'computer',(4.5,1.16,10.4),p,math.pi,.45)
    s.prop('medicine',(6.4,1.16,10.15),p,.6)
    s.box('CardTerminal',(5.4,1.22,10.05),(.22,.12,.3),'2d3438',p)
    s.box('PrescriptionTray',(7.3,1.19,10.25),(.6,.06,.4),'cfe3d8',p)
    # Back shelving full of boxed medicine under the sign and cross.
    s.box('BackShelving',(5.7,1.3,11.9),(5.4,2.6,.36),'dcc7a1',p,True)
    goods=['e9e4d8','f2b84b','9fd3c7','f29e7b','b9c8e8','e38b3c','cfe3d8','f4f1ea']
    for row,y in enumerate([.55,1.15,1.75,2.35]):
        s.box('Shelf',(5.7,y-.2,11.78),(5.3,.04,.32),'b89d74',p)
        for i in range(9):s.box('MedicineBox',(3.45+i*.56,y,11.8),(.36,.34,.24),goods[(i+row*3)%len(goods)],p)
    s.sign('PharmacyBackSign','FARMACIA',(5.0,3.6,12.06),3.4,p,PHARMACY,size=40,height=.75)
    for size in [(.22,.75,.04),(.75,.22,.04)]:s.box('PharmacyCross',(7.6,3.6,12.06),size,'3cc46a',p)
    # Self-service: wall shelf by the stair wall and a gondola in the annex.
    s.box('WallShelf',(6.4,1.1,4.87),(4.4,2.2,.4),'f4f1ea',p,True)
    for y in [.6,1.2,1.8]:
        for i in range(7):s.box('ShelfGoods',(4.55+i*.62,y,5.0),(.4,.3,.2),goods[(i+int(y*5))%len(goods)],p)
    s.box('Gondola',(12.5,.6,10.9),(4.6,1.2,.8),'f4f1ea',p,True)
    s.box('GondolaTop',(12.5,1.23,10.9),(4.8,.06,.9),PHARMACY,p)
    for dz in [-.42,.42]:
        for y in [.35,.85]:
            for i in range(7):s.box('ShelfGoods',(10.6+i*.63,y,10.9+dz),(.42,.3,.06),goods[(i+int(y*4))%len(goods)],p)
    s.prop('bandage',(11.6,1.26,10.9),p,.6)
    s.prop('first_aid_kit',(13.4,1.26,10.9),p,.6)
    # Waiting chairs by the glass, facing the counter side of the shop.
    for z in [8.0,9.0]:turned_prop(s,'chair',(2.75,0,z),p,-1.5708,.85)
    s.plant((15.3,0,5.4),p)
    for x,z in [(5.6,8.4),(12.5,8.3)]:
        s.box('LightPanel',(x,5.25,z),(2.5,.07,1),'fff4d9',p)
        s.node('Light','OmniLight3D',p,'position = '+v((x,4,z))+'\nlight_energy = 0.9\nomni_range = 9')

def deck_ramp(s,r,low,high,span,along_x):
    """Gentle ramp onto the 0.28-high helipad deck, rising from `low` to `high` along X or Z."""
    a=lambda u,y,w:(u,y,w) if along_x else (w,y,u)
    pts=[a(low,0,span[0]),a(low,0,span[1]),a(high,.28,span[0]),a(high,.28,span[1]),a(high,0,span[0]),a(high,0,span[1])]
    body=s.node('DeckRamp','StaticBody3D',r)
    s.node('Collision','CollisionShape3D',body,'shape = '+s.res('ConvexPolygonShape3D','points = PackedVector3Array('+', '.join(', '.join(str(c) for c in pt) for pt in pts)+')'))
    tilt=math.atan(.28/(high-low))
    s.box('DeckRampSurface',a((low+high)/2,.11,sum(span)/2),a(math.hypot(high-low,.28),.06,span[1]-span[0]),'3c6261',r,False,(0,0,tilt) if along_x else (-tilt,0,0))

def roof_access(s):
    """Walkable roof (31 Oct 2026): parapet with coping, roof slabs round the top flight's
    opening and the stair house over it. MainRoof stays as the hidden full-size bounds that
    building_outlines() and the facade pass read. Node names here avoid "roof": building_outlines()
    would add eaves and corner posts to them."""
    r=s.node('Azotea',props='position = '+v((0,ROOF_Y,0)))
    COPING='478e91'; ANNEX='dce6df'
    # Parapet hides the slab edge (from y -.25) and stands 1.2 above the roof.
    for (x0,x1,z0,z1),c in [((-9.2,9.2,-12.4,-12.1),'edf0e8'),((-9.2,9.2,19.8,20.1),'edf0e8'),
            ((-9.2,-8.9,-12.1,-2.9),'edf0e8'),((-9.2,-8.9,2.9,19.8),'edf0e8'),
            ((8.9,9.2,-12.1,-2.15),'edf0e8'),((8.9,9.2,12.1,19.8),'edf0e8'),
            ((15.8,16.1,2.9,12.1),ANNEX),((9.2,15.8,11.8,12.1),ANNEX)]:
        s.box('Parapet',((x0+x1)/2,.475,(z0+z1)/2),(x1-x0,1.45,z1-z0),c,r,True)
        s.box('ParapetCoping',((x0+x1)/2,1.26,(z0+z1)/2),(x1-x0+.1,.12,z1-z0+.1),COPING,r)
    # Walkable slabs (top at the roof level) round the opening x 5.3..13.4, z -1.8..2.4, and
    # the matching floor-3 ceiling pieces below them.
    for (x0,x1,z0,z1) in [(-9.2,5.3,-12.4,20.1),(5.3,9.2,-12.4,-1.8),(5.3,9.2,2.4,20.1),(8.9,13.4,-2.1,-1.8),
            (8.9,16.1,2.4,12.1),(13.4,16.1,-2.1,2.4)]:
        s.box('TopSlab',((x0+x1)/2,-.125,(z0+z1)/2),(x1-x0,.25,z1-z0),'87a7a5',r,True)
    for (x0,x1,z0,z1) in [(-8.9,5.3,-12.1,19.8),(5.3,8.9,-12.1,-1.8),(5.3,8.9,2.4,19.8),(8.9,13.4,-1.95,-1.8),
            (8.9,15.95,2.4,11.95),(13.4,15.95,-1.95,2.4)]:
        s.box('TopCeiling',((x0+x1)/2,-.265,(z0+z1)/2),(x1-x0,.02,z1-z0),FLOOR,r)
    # Stair house over the whole top flight (open above it, like the floor openings, so the
    # camera keeps its distance) and the arrival landing; its door opens onto the annex roof.
    for p,size in [((16,1.8,.375),(.3,3.6,5.05)),((10.575,1.8,-2),(11.15,3.6,.3)),((5.15,1.8,.375),(.3,3.6,5.05)),
            ((9.25,1.8,2.75),(8.5,3.6,.3)),((15.85,1.8,2.75),(.6,3.6,.3)),((14.55,3.25,2.75),(2,.7,.3))]:
        s.box('StairHouseWall',p,size,ANNEX,r,True)
    s.box('StairHouseCap',(10.575,3.7,.375),(11.6,.2,5.4),COPING,r,True)
    s.box('StairHouseCeiling',(10.575,3.59,.375),(10.9,.02,4.8),WALL,r)
    side_sign(s,'ArrivalSign',[('AZOTEA',44,.1)],(15.8,2.1,-.6),2.2,1.0,r,ROOF_TINT,-1.5708)
    s.sign('RoofStairSign','ESCALERAS',(14.55,3.25,2.95),1.9,r,ROOF_TINT,rot=0,size=22,height=.45)
    # Hinged on the side-wall jamb (31 Oct 2026, user request): it swings inward and rests
    # along the stair house's side wall, clear of the arrival sign and the landing.
    hinge_door(s,'RoofDoor',r,(15.5,0,2.75),1.9,2.85,-1.6,'6c8989',along_x=True,reverse=True)
    deck_ramp(s,r,-8.3,-7.0,(-1.6,1.6),True)
    deck_ramp(s,r,6.3,5.0,(1.4,4.0),False)
    for x in [7.5,12.5]:
        s.box('LightPanel',(x,3.55,.3),(2,.05,.8),'fff4d9',r)
        s.node('Light','OmniLight3D',r,'position = '+v((x,3,.3))+'\nlight_energy = 0.8\nomni_range = 8')
    # Eaves and corner posts that building_outlines() used to derive from StairRoof.
    # (The inner rear corner post now stood in the open lounge, so it is left out.)
    for z in [-1.98,11.98]:
        s.box('AnnexEave',(12.5,16.695,z),(7.2,.28,.22),'b3a183')
        # (The front inner corner post at x=9.02 stood inside the floor-3 stairwell; left out.)
        s.box('AnnexCorner',(15.98,8.3475,z),(.2,16.695,.2),'b3a183')
    s.box('AnnexEave',(15.98,16.695,5),(.22,.28,14.2),'b3a183')

def lift_tower(s):
    """Elevator tower outside the right wall (31 Oct 2026): four stops, the last on the
    roof. Its doors open through the old blank side wall into a lobby on every floor."""
    top=ROOF_Y+LIFT_TOP+.3
    for p,size in [((-14.45,top/2-.1,0),(.3,top+.2,5.8)),((-11.8,top/2-.1,-2.75),(5.6,top+.2,.3)),((-11.8,top/2-.1,2.75),(5.6,top+.2,.3)),
            ((-9.15,top-.16,0),(.3,.32,5.5))]:
        s.box('LiftTowerWall',p,size,'edf0e8',solid=True)
    s.box('LiftTowerCap',(-11.8,top+.1,0),(5.9,.2,6.1),'478e91',solid=True)
    for y in [5.5,11.1,16.7]:
        s.box('LiftTowerBand',(-14.62,y,0),(.06,.26,5.9),'478e91')
        for z in [-2.92,2.92]:s.box('LiftTowerBand',(-11.8,y,z),(5.65,.26,.06),'478e91')
    for z in [-2.85,2.85]:s.box('LiftTowerCorner',(-14.55,top/2-.1,z),(.2,top+.2,.2),'b3a183')
    s.node('Elevator',props='position = Vector3('+str(LIFT_X)+',0,0)\nrotation = Vector3(0,-1.5707963,0)\nscript = '+s.external('res://scripts/world/hospital_elevator.gd','Script')
        +'\nfloor_ys = Array[float]([0.0, 5.6, 11.2, '+str(ROOF_Y)+'])\ntop_wall_h = '+str(LIFT_TOP)+'\nroof_stop = true')

def build():
    s=Scene()
    s.node('Hospital',parent=None,props='metadata/multistorey = true\nmetadata/floors = 3\nmetadata/remodeled = true')
    s.node('InteriorDetails')
    programs=[['1 · RECEPCIÓN','2 · URGENCIAS','3 · EXÁMENES','SALA DE ESPERA'],['HABITACIÓN 201','HABITACIÓN 202','CUIDADOS INTENSIVOS','QUIRÓFANO'],['IMÁGENES','LABORATORIO','FISIOTERAPIA','CONSULTORIO']]
    for level in range(3):
        f=s.node('Floor'+str(level+1),props='position = '+v((0,H*level,0)))
        # Permanent floor openings for both aligned circulation cores.
        for z in [-8.35,8.35,BACK_Z]:tiled(s,'RoomSlab',(0,-.1,z),(18,.2,7.7),FLOOR,f,True)
        tiled(s,'HallSlab',(0,-.1,0),(4,.2,9),FLOOR,f,True)
        # The shaft moved out to the side tower (31 Oct 2026); its old core is a lift lobby.
        tiled(s,'CoreSlab',(-5.5,-.1,0),(7,.2,9),FLOOR,f,True)
        s.box('LightPanel',(-5.5,5.25,0),(2.5,.07,1),'fff4d9',f)
        s.node('LobbyLight','OmniLight3D',f,'position = '+v((-5.5,4,0))+'\nlight_energy = 0.85\nomni_range = 9')
        if level==0:tiled(s,'StairBase',(5.5,-.1,0),(7,.2,9),FLOOR,f,True)
        tiled(s,'StairFrontAccess',(5.5,-.1,-3.15),(7,.2,2.7),FLOOR,f,True)
        tiled(s,'StairInnerLanding',(3.5,-.1,.3),(3,.2,4.2),FLOOR,f,True)
        tiled(s,'GalleryLink',(5.5,-.1,3.45),(7,.2,2.1),FLOOR,f,True)
        # Existing envelope and entrance axes are retained, including the side annex.
        for side in [-1,1]:
            for z in [-8.35,8.35,BACK_Z]:
                # The glass wall between the stair-side lounge and annex is gone (31 Oct 2026).
                if side==1 and z==8.35:continue
                s.box('Sill',(side*9,.7,z),(.18,1.4,7.7),'d6e2df',f,True)
                s.box('Glass',(side*9,2.65,z),(.08,2.5,5.2),'aac9d0',f,True,glass=True)
                s.box('Lintel',(side*9,4.65,z),(.18,1.5,7.7),'edf0e8',f,True)
                for dz in [-3.225,3.225]:s.box('SidePier',(side*9,2.65,z+dz),(.18,2.5,1.25),'edf0e8',f,True)
                for dz in [-2.6,0,2.6]:s.box('Mullion',(side*8.9,2.7,z+dz),(.12,2.6,.08),'e8ede6',f)
            # Right wall of the core, open in the middle for the tower elevator's doors.
            if side==-1:
                for z in [-3.55,3.55]:s.box('CenterWall',(-9,2.7,z),(.18,5.4,1.9),'edf0e8',f,True)
        s.box('CornerFiller',(9,2.7,12.1),(.3,5.4,.3),WALL,f,True)
        for x in [-5.4,5.4]:
            for z in [-12.2,REAR]:
                s.box('FacadeSill',(x,.65,z),(7.2,1.3,.18),'edf0e8',f,True)
                s.box('FacadeGlass',(x,2.6,z),(4.8,2.6,.08),'aac9d0',f,True,glass=True)
                for dx in [-3,3]:s.box('FacadePier',(x+dx,2.6,z),(1.2,2.6,.18),'edf0e8',f,True)
                for dx in [-2.4,0,2.4]:s.box('FacadeMullion',(x+dx,2.6,z-.07),(.09,2.6,.14),'6c8989',f)
                for yy in [1.3,3.9]:s.box('FacadeFrame',(x,yy,z-.07),(4.9,.12,.14),'6c8989',f)
                s.box('FacadeLintel',(x,4.65,z),(7.2,1.5,.18),'edf0e8',f,True)
        for z in [-12.2,REAR]:
            s.box('FacadeHeader',(0,4.6,z),(3.6,1.6,.18),'edf0e8',f,True)
            s.box('FacadeHeaderInterior',(0,4.6,z+(.1 if z<0 else -.1)),(3.6,1.6,.02),WALL,f)
            # Only the front entrance stays open; the rear once led to the removed wing.
            if level or z>0:s.box('FacadeCenter',(0,1.9,z),(3.6,3.8,.18),'edf0e8',f,True)
        # Four corner rooms; doors open into a 4-unit central hallway.
        for idx,(x,z) in enumerate([(5.5,-8.35),(5.5,BACK_Z),(-5.5,BACK_Z),(-5.5,-8.35)]):
            side=1 if x>0 else -1; front=1 if z>0 else -1
            room_tint=ROOM_TINTS[level][idx]
            for dz in [-2.75,2.75]:
                s.box('Partition',(side*2,2.7,z+dz),(.14,5.4,2.2),WALL,f,True)
                # Floor-coloured wayfinding stripe on the hall face of every partition.
                s.box('WayfindingStripe',(side*1.92,1.05,z+dz),(.02,.22,2.2),FLOOR_TINTS[level],f)
            s.box('DoorHeader',(side*2,4.4,z),(.14,2,3.3),tint(room_tint,.1),f,True)
            # Inner wall: toward the core for front rooms, toward the lounge for back rooms.
            s.box('CrossWall',(x,2.7,z-front*3.85),(7,5.4,.14),WALL,f,True)
            s.box('FeatureWall',(x,2.7,z-front*3.77),(6.7,5.3,.02),tint(room_tint,.62),f)
            skin_room(s,f,x,z,side,front,tint(room_tint,.62))
            tiled(s,'RoomBorder',(x,.026,z),(6.7,.025,7.3),tint(room_tint,.78),f)
            room=s.node('Room'+str(idx+1),parent=f,props='position = '+v((x,0,z))+('\nrotation = Vector3(0,3.14159265,0)' if x<0 else ''))
            # Reception has its own sign on its feature wall.
            if (level,idx)!=(0,0):s.sign('RoomLabel',programs[level][idx],(x,3.7,z+3.65),6.3,f,room_tint,size=29)
            # Wall plaque beside the door, facing the hall; Imágenes' plaque teaches "imaging".
            plaque='ImagingDoorPlaque' if (level,idx)==(2,0) else 'DoorPlaque'
            side_sign(s,plaque,[(programs[level][idx],20,0)],(side*1.88,2.15,z-front*2.75),2.0,.5,f,room_tint,-1.5708*side,plaque!='DoorPlaque')
            s.node('Light','OmniLight3D',f,'position = '+v((x,4,z))+'\nlight_energy = 0.85\nomni_range = 9')
            s.box('LightPanel',(x,5.25,z),(2.5,.07,1),'fff4d9',f)
            former_wing_displays(s,room,level,idx)
            if level==0 and idx==0:furnish(s,room,0,0,room_tint)
            elif level==0 and idx==3:waiting_room(s,room,room_tint)
            elif level==2 and idx==0:
                s.prop('x_ray_machine',(0,0,1),room,.8)
                s.prop('medical_monitor',(-2,1,-1.8),room,.8)
                s.box('Console',(-2,.5,-1.8),(1,1,1),'9dbbb8',room,True)
                s.prop('chair',(-2,0,-3),room,.8)
            elif level==2 and idx==1:
                s.box('LabBench',(0,.65,1.8),(4.5,1.3,1.2),'9dbbb8',room,True)
                for dx in [-1,0,1]:
                    s.box('SampleTray',(dx,1.34,1.8),(.7,.08,.65),'e9dec7',room)
                    for dz in [1.6,1.9]:s.orb('SampleTube',(dx,1.55,dz),(.12,.36,.12),'9dbbb8',room)
                s.prop('thermometer',(-1,1.42,1.6),room,.65)
                s.prop('computer',(1,1.3,1.8),room,.65)
                s.prop('surgical_mask',(0,1.42,1.6),room,.7)
                s.prop('chair',(1,0,.1),room,.85)
            elif level==2 and idx==2:furnish(s,room,2,1,room_tint)
            elif level==2 and idx==3:
                s.prop('desk',(0,0,1.6),room,.9)
                s.prop('computer',(0,1.0,1.6),room,.65)
                s.prop('chair',(0,0,-.3),room,.85)
                s.prop('book',(-1,1,1.6),room,.7)
                s.plant((2.4,0,3),room)
            else:
                furnish(s,room,0,1,room_tint)
                if level==1 and idx==3:
                    s.box('SurgicalLampArm',(0,3.8,1),(.12,1.2,.12),'819d99',room)
                    s.orb('SurgicalLight',(0,3.1,1),(1.2,.2,1.2),'fff4d9',room)
                    s.prop('surgical_mask',(1.8,1.75,-2.5),room,.7)
        title='PLANTA '+str(level+1)
        # No hanging corridor signs: floor identity is on the elevator header, the stair
        # arrival sign and the alcove directory; rooms have door plaques.
        # Floor directory on the lift lobby's front wall, facing the tower elevator.
        s.sign('LobbyDirectory',title+'\n'+'  ·  '.join(programs[level][:2])+'\n'+'  ·  '.join(programs[level][2:]),(-5.5,2.5,-4.37),4.6,f,FLOOR_TINTS[level],rot=0,size=34,height=2.0)
        s.plant((-7.9,0,-3.6),f)
        # A broad, straight stair uses the existing annex; no tight switchback.
        # Two hall approaches: front z=-3.15 and rear z=3.45 on EVERY floor.
        x0=5.0; x1=13.4; run=x1-x0; z0=-1.8; z1=2.4; width=z1-z0
        tiled(s,'AnnexRearSlab',(12.5,-.1,7.2),(7,.2,9.6),FLOOR,f,True)
        tiled(s,'StairOuterLanding',(14.7,-.1,.2),(2.6,.2,4.4),FLOOR,f,True)
        if level==0:tiled(s,'AnnexGround',(12.5,-.1,.2),(7,.2,4.4),FLOOR,f,True)
        # No flat landing guards (31 Oct 2026): every opening is filled by the flight that
        # starts on that floor, whose own rails guard both edges; the flat rails poked out.
        # Every floor climbs; the third flight (31 Oct 2026) rises to the roof stair house.
        rise=H if level<2 else ROOF_Y-2*H
        nxt=TINTS[level+1]
        # Continuous sloped slab; the underside follows the rise to retain headroom.
        pts=[(x0,-.35,z0),(x0,-.35,z1),(x1,rise-.35,z0),(x1,rise-.35,z1),(x0,0,z0),(x0,0,z1),(x1,rise,z0),(x1,rise,z1)]
        values=', '.join(', '.join(str(c) for c in pt) for pt in pts)
        body=s.node('StairRamp','StaticBody3D',f)
        s.node('Collision','CollisionShape3D',body,'shape = '+s.res('ConvexPolygonShape3D','points = PackedVector3Array('+values+')'))
        for step in range(28):
            top=(step+.5)*rise/28
            x=x0+(step+.5)*run/28
            s.box('SolidStep',(x,top-.2,(z0+z1)/2),(run/28,.4,width),OAK,f)
            s.box('StepEdge',(x-run/56+.03,top+.006,(z0+z1)/2),(.06,.014,width),nxt,f)
        angle=math.atan2(rise,run)
        for z in [z0-.05,z1+.05]:
            # Destination-floor colour along both sides of the flight.
            s.box('StairStringer',((x0+x1)/2,rise/2-.15,z),(math.hypot(run,rise),.55,.06),nxt,f,False,(0,0,angle))
        for z in [z0,z1]:
            s.box('StairGuardCollision',((x0+x1)/2,rise/2+.48,z),(math.hypot(run,rise)-.35,.96,.08),'789993',f,True,(0,0,angle),visible=False)
            # End posts are set back from the landing thresholds.
            for t in [.04,.25,.5,.75,.96]:
                s.box('StairPost',(x0+t*run,t*rise+.5,z),(.07,1,.07),STEEL,f)
            for y in [.45,1.05]:s.box('StairHandrail',((x0+x1)/2,rise/2+y,z),(math.hypot(run,rise)-.35,.08,.08),RAIL if y>1 else STEEL,f,False,(0,0,angle))
        up='↑ PLANTA '+str(level+2) if level<2 else '↑ AZOTEA'
        s.sign('AscentSign',up,(4.1,2.7,-4.4),2.6,f,nxt,rot=0,size=22,height=.55)
        # Arrival marker straight ahead at the top of each flight (annex pier).
        side_sign(s,'ArrivalSign',[(str(level+1),120,.15),('PLANTA',30,-.5)],(15.82,2.6,-1),1.8,1.5,f,FLOOR_TINTS[level],-1.5708)
        lounge(s,f,level)
        # The anatomy model stands where floor 2's stair-side sofa was, facing the hall.
        if level==1:anatomy_model(s,f,(5.6,0,11.3))
        if level==0:pharmacy(s,f)
        s.sign('StairFrontSign','ESCALERAS · '+title,(6.9,2.7,-4.4),2.6,f,FLOOR_TINTS[level],rot=0,size=22,height=.55)
        # Preserve annex envelope; actual windows replace the blank outer wall.
        s.box('AnnexSill',(16,.65,5),(.18,1.3,14),'dce6df',f,True)
        s.box('AnnexLintel',(16,4.65,5),(.18,1.5,14),'dce6df',f,True)
        for z in [-1,5,11]:s.box('AnnexPier',(16,2.6,z),(.18,2.6,2),'dce6df',f,True)
        for z in [2,8]:
            s.box('AnnexWindow',(16,2.6,z),(.08,2.6,4),'aac9d0',f,True,glass=True)
            for dz in [-2,0,2]:s.box('AnnexMullion',(16.06,2.6,z+dz),(.14,2.6,.08),'6c8989',f)
            for y in [1.3,3.9]:s.box('AnnexWindowFrame',(16.06,y,z),(.14,.12,4.1),'6c8989',f)
        for z in [-2,12]:
            s.box('AnnexEnd',(12.5,2.7,z),(7,5.4,.18),'dce6df',f,True)
            s.box('AnnexEndBand',(12.5,5.5,z),(7,.2,.2),'b6c9bd',f,True)
        s.box('AnnexSideBand',(16,5.5,5),(.2,.2,14.2),'b6c9bd',f,True)
        s.box('AnnexFrontClosure',(9,2.7,-3.25),(.18,5.4,2.5),'edf0e8',f,True)
        skin_shared(s,f,level)
        if level:s.plant((15.3,0,5.0) if level==1 else (14.5,0,10),f)
    lift_tower(s)
    # Hidden full-size roof bounds; Azotea/TopSlab is the walkable roof and TopCeiling the
    # warm floor-3 ceiling (both split round the top stair opening since 31 Oct 2026).
    s.box('MainRoof',(0,16.8,(REAR-12.2)/2),(18.4,.25,REAR+12.2+.4),'87a7a5',visible=False)
    # Main-block eaves and corner posts, formerly derived at runtime from MainRoof by
    # building_outlines(); its +X eave ran through the open annex on floor 3 (31 Oct 2026),
    # so that side keeps only the stretches over real exterior wall.
    s.nodes[-1]+='metadata/authored_outline = true\n'
    T='b3a183'; E=16.695
    for z in [-12.28,REAR+.08]:s.box('MainEave',(0,E,z),(18.4,.28,.22),T)
    s.box('MainEave',(-9.08,E,(REAR-12.2)/2),(.22,.28,REAR+12.6),T)
    for z0,z1 in [(-12.4,-2.0),(12.0,REAR+.2)]:s.box('MainEave',(9.08,E,(z0+z1)/2),(.22,.28,z1-z0),T)
    for x in [-9.08,9.08]:
        for z in [-12.28,REAR+.08]:s.box('MainCorner',(x,E/2,z),(.2,E,.2),T)
    roof_access(s)
    for y in [5.5,11.1,16.7]:s.box('FacadeBand',(0,y,-12.35),(18.4,.26,.22),'478e91')
    s.box('MedicalCrossVertical',(0,14.2,-12.4),(.35,1.6,.14),'b94c4c')
    s.box('MedicalCrossHorizontal',(0,14.2,-12.41),(1.4,.35,.14),'b94c4c')
    s.node('HospitalHelipad',props='position = Vector3(-1,16.925,-1)',instance=s.external('res://scenes/rooftops/hospital_helipad.tscn'))
    for i, node in enumerate(s.nodes):
        if '[node name="Planter"' in node: node += 'metadata/word_key = "planter"\n'
        if '[node name="MonitorStand"' in node: node += 'metadata/word_key = "stand"\n'
        if '[node name="ImagingDoorPlaquePanel"' in node: node += 'metadata/word_key = "imaging"\n'
        if '[node name="HospitalBed"' in node and 'parent="Floor1/Room3"' in node: node += 'metadata/word_key = "examination bed"\n'
        if '[node name="HospitalBed"' in node and 'parent="Floor2/Room4"' in node: node += 'metadata/word_key = "treatment table"\n'
        s.nodes[i] = node
    # "sheet" lived only on the removed wing's bed; the examination bed's sheet keeps it.
    s.nodes.append('[node name="Sheet" parent="Floor1/Room3/HospitalBed"]\nmetadata/word_key = "sheet"\n')
    s.save(ROOT/'scenes/buildings/hospital.tscn')
    print('Built remodeled hospital with aligned circulation cores')
