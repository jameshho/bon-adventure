"""Small shared writer for editable Godot primitive scenes."""
import math
class Scene:
    def __init__(self): self.resources=[]; self.nodes=[]; self.cache={}; self.ext={}; self.names=set()
    def res(self,typ,body):
        key=(typ,body)
        if key not in self.cache:
            ident='r'+str(len(self.cache)+1);self.cache[key]=ident
            self.resources.append(f'[sub_resource type="{typ}" id="{ident}"]\n{body}\n')
        return f'SubResource("{self.cache[key]}")'
    def external(self,path,typ='PackedScene'):
        if path not in self.ext:self.ext[path]=(f'e{len(self.ext)+1}',typ)
        return f'ExtResource("{self.ext[path][0]}")'
    def node(self,name,typ='Node3D',parent='.',props='',instance=None):
        original=name; count=1
        while (parent,name) in self.names:
            count+=1; name=original+str(count)
        self.names.add((parent,name))
        suffix=f' instance={instance}' if instance else f' type="{typ}"'
        par='' if parent is None else f' parent="{parent}"'
        self.nodes.append(f'[node name="{name}"{suffix}{par}]\n{props}\n')
        return name if parent=='.' else f'{parent}/{name}'
    def box(self,name,p,size,c,parent='.',solid=False,rotation=None,visible=True,glass=False):
        mesh=self.res('BoxMesh','size = '+v(size)); mat=self.res("StandardMaterial3D","transparency = 1\nalbedo_color = Color(0.58, 0.78, 0.86, 0.22)\nroughness = 0.18\ncull_mode = 2") if glass else self.mat(c)
        path=self.node(name,'MeshInstance3D',parent,'position = '+v(p)+'\nmesh = '+mesh+'\nmaterial_override = '+mat+(f'\nrotation = {v(rotation)}' if rotation else '')+('\nvisible = false' if not visible else ''))
        if solid:
            body=self.node('Body','StaticBody3D',path)
            self.node('Shape','CollisionShape3D',body,'shape = '+self.res('BoxShape3D','size = '+v(size)))
        return path
    def orb(self,name,p,size,c,parent='.'):
        mesh=self.res('SphereMesh','radius = 0.5\nheight = 1.0\nradial_segments = 12\nrings = 6')
        self.node(name,'MeshInstance3D',parent,'position = '+v(p)+'\nscale = '+v(size)+'\nmesh = '+mesh+'\nmaterial_override = '+self.mat(c))
    def plant(self,p,parent):
        x,y,z=p
        self.box('Planter',(x,y+.3,z),(.6,.6,.6),'c7b391',parent,True)
        self.box('PlantStem',(x,y+.8,z),(.06,.7,.06),'6f8662',parent)
        self.orb('Leaves',(x,y+1.15,z),(.95,1.1,.95),'7f9c76',parent)
    def mat(self,c):
        rgb=[int(c[i:i+2],16)/255 for i in (0,2,4)]
        return self.res('StandardMaterial3D',f'albedo_color = Color({rgb[0]}, {rgb[1]}, {rgb[2]}, 1)\nroughness = 0.82')
    def text(self,name,text,p,parent='.',rot=math.pi,size=38):
        self.node(name,'Label3D',parent,'position = '+v(p)+f'\nrotation = Vector3(0, {rot}, 0)\ntext = "'+text.replace('\n','\\n')+f'"\nfont_size = {size}\npixel_size = 0.008\noutline_size = 4\nno_depth_test = false')
    def sign(self,name,text,p,width=5,parent='.',color='386f78',rot=math.pi,size=34,height=.85):
        self.box(name+'Panel',p,(width,height,.09),color,parent)
        self.text(name,text,(p[0],p[1],p[2]-.06 if rot else p[2]+.06),parent,rot,size)
    def prop(self,key,p,parent,scale=1):
        path='res://scenes/props/vocabulary/'+key+'.tscn'
        self.node(key.title().replace('_',''),parent=parent,props='position = '+v(p)+'\nscale = '+v((scale,)*3),instance=self.external(path))
    def save(self,path):
        ext=[f'[ext_resource type="{typ}" path="{p}" id="{i}"]\n' for p,(i,typ) in self.ext.items()]
        path.write_text('[gd_scene format=3]\n\n'+'\n'.join(ext+self.resources+self.nodes))
def v(a):return 'Vector3('+', '.join(f'{x:.6f}' for x in a)+')'
