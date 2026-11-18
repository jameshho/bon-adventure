import vtracer, re, sys, json
def trace(src, out, **kw):
    args=dict(colormode='color', hierarchical='cutout', mode='polygon', filter_speckle=10, color_precision=5, layer_difference=28, corner_threshold=60, length_threshold=4.0, max_iterations=10, splice_threshold=45, path_precision=2)
    args.update(kw)
    vtracer.convert_image_to_svg_py(src, out, **args)
def regions(svg):
    s=open(svg).read()
    out=[]
    for m in re.finditer(r'<path d="([^"]+)" fill="(#[0-9a-fA-F]{6})" transform="translate\(([-\d.]+),([-\d.]+)\)"', s):
        d,fill,tx,ty=m.group(1),m.group(2),float(m.group(3)),float(m.group(4))
        subs=[]
        for sub in d.split('M')[1:]:
            nums=[float(v) for v in re.findall(r'-?\d+\.?\d*', sub)]
            pts=[(nums[i]+tx, nums[i+1]+ty) for i in range(0,len(nums)-1,2)]
            if len(pts)>2: subs.append(pts)
        if not subs: continue
        area=0
        for pts in subs:
            a=0
            for i in range(len(pts)):
                x1,y1=pts[i]; x2,y2=pts[(i+1)%len(pts)]
                a+=x1*y2-x2*y1
            area+=a/2
        xs=[p[0] for pts in subs for p in pts]; ys=[p[1] for pts in subs for p in pts]
        out.append(dict(fill=fill, area=abs(area), bbox=(min(xs),min(ys),max(xs),max(ys)), subs=subs))
    return out
if __name__=='__main__':
    src,out=sys.argv[1],sys.argv[2]
    trace(src,out)
    rs=regions(out)
    print(len(rs),'regions')
    for r in sorted(rs,key=lambda r:-r['area'])[:int(sys.argv[3]) if len(sys.argv)>3 else 60]:
        print(r['fill'], 'area %7.0f'%r['area'], 'bbox %6.1f %6.1f %6.1f %6.1f'%r['bbox'], 'paths',len(r['subs']))
