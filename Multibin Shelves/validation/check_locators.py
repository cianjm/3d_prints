from pathlib import Path
import numpy as np
import json
s=Path(__file__).with_name('check_model.py').read_text()
exec(s[:s.index('results={}')])

# Check actual STL triangles against each new convex locator volume. Unlike the
# previous square envelope this includes the source's diagonal faces and notches.
triangles=np.fromfile(REF,dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')]),offset=84)['v'].astype(float)
triangles=triangles[triangles[:,:,2].min(1)<5.11]
def corner(z,c):
    plane=43.6-5.447764+np.sqrt(2)*(min(max(z,0),.4)-.4+max(z-3.6,0)+c)
    return np.array([[25,25],[plane-25,25],[25,plane-25]])
def notch(z,c):
    tip=19.5+max(z,0)+c
    diagonal=19.5-2.27817+np.sqrt(2)*(max(z,0)+c)
    return np.array([[tip,-(tip-diagonal)],[25,-(25-diagonal)],[25,25-diagonal],[tip,tip-diagonal]])
def planes(bottom,top,z0,z1):
    n=len(bottom)
    v=np.concatenate([np.column_stack((bottom,np.full(n,z0))),np.column_stack((top,np.full(n,z1)))])
    faces=[list(range(n-1,-1,-1)),list(range(n,2*n))]+[[i,(i+1)%n,(i+1)%n+n,i+n] for i in range(n)]
    out=[]
    for f in faces:
        a,b,c=v[f[:3]]
        normal=np.cross(b-a,c-a); normal/=np.linalg.norm(normal)
        out.append((normal,np.dot(normal,a)))
    return v,out
def intersects(poly,ps):
    for normal,d in ps:
        out=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            da=np.dot(normal,a)-d+0.000001; db=np.dot(normal,b)-d+0.000001
            if da<=0: out.append(a)
            if (da<=0)!=(db<=0): out.append(a+(b-a)*da/(da-db))
        poly=out
        if not poly: return False
    return True

for clearance in [.10,.05]:
    features=[]
    levels=[-.02,0,.4,3.6,5.1]
    for lo,hi in zip(levels,levels[1:]):
        features.append(('corner',*planes(corner(lo,clearance),corner(hi,clearance),lo,hi)))
    features.append(('notch',*planes(notch(0,clearance),notch(2.3,clearance),-.02,2.3)))
    collisions=[]; checked=0
    for cx in [0,50]:
        for cy in [0,50]:
            for rotation in range(4):
                local=triangles-np.array([cx,cy,0])
                for _ in range(rotation): local=local[:,:,[1,0,2]]*np.array([-1,1,1])
                for name,v,ps in features:
                    lo=v.min(0); hi=v.max(0)
                    candidates=local[np.all(local.max(1)>=lo,axis=1)&np.all(local.min(1)<=hi,axis=1)]
                    for t in candidates:
                        checked+=1
                        if intersects(list(t),ps): collisions.append((cx,cy,rotation,name,t.tolist()))
    print('Locator clearance',clearance,'triangles checked',checked,'intersections',len(collisions),flush=True)
    if collisions:
        (ROOT/'validation'/'locator_collisions.json').write_text(json.dumps(collisions[:20],indent=2))
    assert not collisions

exports=[('ridge_only',['baseOnly=true','removeBase=true'],'Multibin_Ridge_Only_Fit_Test.stl'),
         ('full',[],'MultiConnect_Multibin.stl'),
         ('full_no_base',['removeBase=true'],'MultiConnect_Multibin_No_Base.stl'),
         ('base_test',['baseOnly=true'],'Multibin_Base_Fit_Test.stl'),
         ('small_locators',['unitsWide=1','unitsDeep=1','baseOnly=true','removeBase=true'],None),
         ('large_locators',['unitsWide=2','unitsDeep=3','removeBase=true'],None)]
results={}
for name,defs,destination in exports:
    path,r=run(name,defs)
    assert r.returncode==0 and 'WARNING:' not in r.stderr and 'ERROR:' not in r.stderr
    results[name]=mesh_check(path)
    if destination: (ROOT/destination).write_bytes(path.read_bytes())
(ROOT/'validation'/'locator_results.json').write_text(json.dumps(results,indent=2))
print('All locator collision checks and mesh checks passed.',flush=True)
