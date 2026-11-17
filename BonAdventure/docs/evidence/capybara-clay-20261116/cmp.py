import sys
from trace import trace, regions
EV="/Users/james/Documents/Codex/Bon Adventure/BonAdventure/docs/evidence/capybara-clay-20261116/"
RECTS=[("f34",20,360),("front",381,290),("side",695,450),("back",1192,290),("r34",1521,450)]
def solid(fill):
    r=int(fill[1:3],16); b=int(fill[5:7],16)
    return r-b>100
def polys(svg, sx=1.0, ox=0.0, oy=0.0):
    out=[]
    for r in regions(svg):
        if not solid(r['fill']): continue
        if r['area']<40: continue
        for pts in r['subs']:
            out.append([(x*sx+ox, y*sx+oy) for x,y in pts])
    return out
def hspan(ps, y, x0, x1):
    xs=[]
    for pts in ps:
        n=len(pts)
        for i in range(n):
            (ax,ay),(bx,by)=pts[i],pts[(i+1)%n]
            if (ay<=y<by) or (by<=y<ay):
                x=ax+(y-ay)*(bx-ax)/(by-ay)
                if x0<=x<=x1: xs.append(x)
    return (min(xs),max(xs)) if xs else None
def vspan(ps, x, y0, y1, x0, x1):
    ys=[]
    for pts in ps:
        if not any(x0<=p[0]<=x1 for p in pts): continue
        n=len(pts)
        for i in range(n):
            (ax,ay),(bx,by)=pts[i],pts[(i+1)%n]
            if (ax<=x<bx) or (bx<=x<ax):
                y=ay+(x-ax)*(by-ay)/(bx-ax)
                if y0<=y<=y1: ys.append(y)
    return (min(ys),max(ys)) if ys else None
trace(EV+"reference.png","ref.svg")
trace(EV+"turnaround.png","model.svg")
ref=polys("ref.svg")
# model: split per view
mod_all=regions("model.svg")
off=0; mod={}
for name,rx,rw in RECTS:
    ps=[]
    for r in mod_all:
        if not solid(r['fill']) or r['area']<40: continue
        for pts in r['subs']:
            cx=sum(p[0] for p in pts)/len(pts)
            if off<=cx<off+rw*2:
                ps.append([((x-off)/2+rx, y/2+195) for x,y in pts])
    mod[name]=ps; off+=rw*2
which=sys.argv[1:] or [n for n,_,_ in RECTS]
for name,rx,rw in RECTS:
    if name not in which: continue
    x0,x1=rx,rx+rw
    print("==",name,"  y: ref L R | model L R | dL dR (model-ref; + = model further right)")
    for y in range(215,526,15):
        a=hspan(ref,y,x0,x1); b=hspan(mod[name],y,x0,x1)
        if a and b: print("y%4d  ref %6.1f %6.1f w%5.1f | mod %6.1f %6.1f w%5.1f | d %+5.1f %+5.1f"%(y,a[0],a[1],a[1]-a[0],b[0],b[1],b[1]-b[0],b[0]-a[0],b[1]-a[1]))
        elif a: print("y%4d  ref %6.1f %6.1f | mod none"%(y,a[0],a[1]))
        elif b: print("y%4d  ref none | mod %6.1f %6.1f"%(y,b[0],b[1]))
    if name in("side","f34","r34"):
        print("--",name," x: ref top bot | model top bot | dTop dBot (+ = model lower)")
        for x in range(x0+10,x1,20):
            a=vspan(ref,x,200,530,x0,x1); b=vspan(mod[name],x,200,530,x0,x1)
            if a and b: print("x%5d  ref %6.1f %6.1f | mod %6.1f %6.1f | d %+5.1f %+5.1f"%(x,a[0],a[1],b[0],b[1],b[0]-a[0],b[1]-a[1]))
            elif a: print("x%5d  ref %6.1f %6.1f | mod none"%(x,a[0],a[1]))
            elif b: print("x%5d  ref none | mod %6.1f %6.1f"%(x,b[0],b[1]))

print("== dark regions (lids/eyes): view fill bbox")
def dark(fill):
    return int(fill[1:3],16)<115 and int(fill[3:5],16)<70
for r in regions("ref.svg"):
    if dark(r['fill']) and r['area']>120 and 270<r['bbox'][1]<330: print("ref  ",r['fill'],"%.0f %.0f %.0f %.0f"%r['bbox'])
off=0
for name,rx,rw in RECTS:
    for r in mod_all:
        b=r['bbox']
        if dark(r['fill']) and r['area']>400 and off<=b[0]<off+rw*2:
            y0=b[1]/2+195
            if 270<y0<330: print("model",name,r['fill'],"%.0f %.0f %.0f %.0f"%((b[0]-off)/2+rx,y0,(b[2]-off)/2+rx,b[3]/2+195))
    off+=rw*2
