from pathlib import Path
import subprocess
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
SCAD = 'C:/Program Files/OpenSCAD/openscad.com'
REF = 'E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Multibin Shells/2x2x0.5 LU - Topped Rail - MultiBin Shell.stl'

def run(name, definitions=(), source=None, extension='stl', extra=()):
    target = ROOT/'validation'/f'{name}.{extension}'
    cmd = [SCAD, '-o', str(target)]
    if extension == 'stl': cmd += ['--export-format','binstl']
    for d in definitions: cmd += ['-D',d]
    cmd += list(extra)+[str(source or ROOT/'MultiConnect_Multibin.scad')]
    p = subprocess.run(cmd, capture_output=True, text=True)
    p.stderr = p.stdout+p.stderr
    (ROOT/'validation'/f'{name}.log').write_text(p.stderr)
    print(name, 'exit',p.returncode, p.stderr.strip(),flush=True)
    return target, p

def mesh_check(path):
    a=np.fromfile(path,dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')]),offset=84)
    v=a['v'].reshape(-1,3)
    vertices, inv=np.unique(v,axis=0,return_inverse=True)
    tri=inv.reshape(-1,3)
    edges=np.sort(np.concatenate([tri[:,[0,1]],tri[:,[1,2]],tri[:,[2,0]]]),axis=1)
    _,counts=np.unique(edges,axis=0,return_counts=True)
    parent=list(range(len(vertices)))
    def find(i):
        while parent[i]!=i:
            parent[i]=parent[parent[i]]
            i=parent[i]
        return i
    for x,y in edges: parent[find(x)]=find(y)
    components=len({find(i) for i in range(len(vertices))})
    result=dict(bounds=[v.min(0).tolist(),v.max(0).tolist()],size=np.ptp(v,axis=0).tolist(),closed=bool(np.all(counts==2)),components=components)
    print(path.name,result,flush=True)
    assert result['closed'] and components==1 and v[:,2].min()>=-0.0001
    return result

results={}
results['default']=mesh_check(ROOT/'MultiConnect_Multibin.stl')
assert abs(results['default']['size'][0]-103.6)<0.001
for name,defs in [
    ('small',['unitsWide=1','unitsDeep=1']),
    ('open_floor',['removeBase=true']),
    ('thicker_clearance',['rimThickness=2.5','shellClearance=0.5','baseThickness=3']),
    ('boundary',['additionalRimHeight=0','bracketDepthPercentage=0','subtractedSlots=1']),
    ('ridge_fit',['grooveClearance=0.1','grooveRoofClearance=0.3']),
    ('ridge_loose',['grooveClearance=0.4','grooveRoofClearance=0.6']),
    ('multipoint',['Connection_Type="Multipoint"']),
    ('multiconnect',['Connection_Type="Multiconnect - Multiboard"']),
    ('opengrid',['Connection_Type="Multiconnect - openGrid"']),
    ('custom',['Connection_Type="Multiconnect - Custom Size"','customDistanceBetweenSlots=30']),
    ('goews',['Connection_Type="GOEWS"'])]:
    p,r=run(name,defs)
    assert r.returncode==0 and 'WARNING:' not in r.stderr and 'ERROR:' not in r.stderr
    results[name]=mesh_check(p)
p,r=run('invalid',['shellClearance=-1'])
assert 'ERROR: Assertion' in r.stderr

fit=ROOT/'validation'/'fit_check.scad'
model=(ROOT/'MultiConnect_Multibin.scad').read_text()
assembly='translate([-totalWidth/2,-totalDepth/2,0]) shelf();'
# Verify a conservative tapered envelope directly against the reference mesh.
# Clip each triangle at profile breakpoints and check its vertices against the
# linear bounds in each band. Convexity then bounds the entire clipped triangle.
ref_mesh=np.fromfile(REF,dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')]),offset=84)
ref_vertices=ref_mesh['v'].reshape(-1,3)
assert np.allclose(ref_vertices.min(0),[-25,-25,0],atol=0.0001)
assert np.allclose(ref_vertices.max(0),[75,75,30],atol=0.0001)
def clip(poly,z,above):
    out=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        ia=(a[2]>=z) if above else (a[2]<=z)
        ib=(b[2]>=z) if above else (b[2]<=z)
        if ia: out.append(a)
        if ia != ib: out.append(a+(b-a)*(z-a[2])/(b[2]-a[2]))
    return out
max_excess=-1e9
for lo,hi in [(0,0.4),(0.4,3.6),(3.6,5.15)]:
    subset=ref_mesh['v'][(ref_mesh['v'][:,:,2].min(1)<hi)&(ref_mesh['v'][:,:,2].max(1)>=lo)].astype(float)
    for tri in subset:
        pts=clip(clip(list(tri),lo,True),hi,False)
        if not pts: continue
        pts=np.array(pts)
        centre=np.round(pts[:,:2].mean(0)/50)*50
        halfwidth=21.4+np.minimum(pts[:,2],0.4)+np.maximum(pts[:,2]-3.6,0)
        excess=(np.abs(pts[:,:2]-centre)-halfwidth[:,None]).max()
        max_excess=max(max_excess,excess)
assert max_excess<0.0001, max_excess
print('Maximum mesh excess outside tapered foot envelope:',max_excess,flush=True)
envelope='''translate([-25,-25.75,2.4]) union() {
    for(x=[0,50],y=[0,50]) translate([x,y,0]) {
        translate([0,0,0.0001]) linear_extrude(height=0.3999,scale=43.6/42.8002) square(42.8002,center=true);
        translate([-21.8,-21.8,0.4]) cube([43.6,43.6,3.2]);
        translate([0,0,3.6]) linear_extrude(height=1.55,scale=46.7/43.6) square(43.6,center=true);
    }
    translate([-25,-25,5.15]) cube([100,100,24.85]);
}'''
# This square-foot envelope checks the original rails only. Added octagonal
# corner and notch locators are checked against actual shell triangles by
# check_locators.py; they intentionally enter this conservative square envelope.
rail_model=model.replace('cornerLocator();','').replace('midpointLocator();','')
fit.write_text(rail_model.replace(assembly,'intersection() {\n'+assembly+'\n'+envelope+'\n}\n'))
p,r=run('fit_check',source=fit)
assert 'Current top level object is empty' in r.stderr
assert 'slot_centres_from_left_mm = [26.4, 51.8, 77.2]' in r.stderr
for name,defs in [('fit_tight',['grooveClearance=0.1']),('invalid_ridge',['grooveRoofClearance=0.1'])]:
    p,r=run(name,defs,source=fit)
    assert ('ERROR: Assertion' if name=='invalid_ridge' else 'Current top level object is empty') in r.stderr

preview=ROOT/'validation'/'assembly_preview.scad'
preview.write_text('include <../MultiConnect_Multibin.scad>\n color([0.2,0.65,0.85]) translate([-25,-25.75,2.4]) import("'+REF+'");\n')
run('assembly_preview',source=preview,extension='png',extra=['--imgsize=1200,900','--camera=0,0,0,60,0,210,350','--viewall','--autocenter'])
run('shelf_preview',extension='png',extra=['--imgsize=1200,900','--camera=0,0,0,60,0,210,350','--viewall','--autocenter'])
run('back_preview',extension='png',extra=['--imgsize=1200,900','--camera=0,0,0,65,0,145,350','--viewall','--autocenter'])
import json
(ROOT/'validation'/'results.json').write_text(json.dumps(results,indent=2))
