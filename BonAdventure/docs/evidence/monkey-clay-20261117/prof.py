import sys
from trace import regions
def solid(fill):
    r=int(fill[1:3],16); b=int(fill[5:7],16)
    return r-b>60
def polys(svg, sx=1.0, ox=0.0, oy=0.0, minarea=30):
    out=[]
    for r in regions(svg):
        if not solid(r['fill']) or r['area']<minarea: continue
        out.append([[(x*sx+ox,y*sx+oy) for x,y in pts] for pts in r['subs']])
    return out
def spans(regs, c, axis, lo, hi, a0, a1):
    """intervals along the other axis where scanline coordinate c (axis 'y' -> horizontal line) is inside"""
    iv=[]
    for subs in regs:
        xs=[]
        for pts in subs:
            n=len(pts)
            for i in range(n):
                (ax,ay),(bx,by)=pts[i],pts[(i+1)%n]
                if axis=='y': p0,q0,p1,q1=ay,ax,by,bx
                else: p0,q0,p1,q1=ax,ay,bx,by
                if (p0<=c<p1) or (p1<=c<p0):
                    xs.append(q0+(c-p0)*(q1-q0)/(p1-p0))
        xs.sort()
        for i in range(0,len(xs)-1,2):
            if xs[i+1]>lo and xs[i]<hi: iv.append((max(xs[i],lo),min(xs[i+1],hi)))
    iv.sort(); out=[]
    for a,b in iv:
        if out and a<=out[-1][1]+1.5: out[-1]=(out[-1][0],max(out[-1][1],b))
        else: out.append((a,b))
    return [(a,b) for a,b in out if b-a>1.5]
if __name__=='__main__':
    regs=polys(sys.argv[1])
    name,x0,x1=sys.argv[2],float(sys.argv[3]),float(sys.argv[4])
    step=int(sys.argv[5]) if len(sys.argv)>5 else 12
    print('==',name,'rows (y: x-intervals)')
    for y in range(120,585,step):
        s=spans(regs,y,'y',x0,x1,0,0)
        if s: print('y%4d'%y,' '.join('%.0f-%.0f'%ab for ab in s))
    print('--',name,'cols (x: y-intervals)')
    for x in range(int(x0),int(x1),step):
        s=spans(regs,x,'x',110,585,0,0)
        if s: print('x%5d'%x,' '.join('%.0f-%.0f'%ab for ab in s))
