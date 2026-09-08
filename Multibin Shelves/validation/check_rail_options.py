from pathlib import Path
s=Path(__file__).with_name('check_model.py').read_text()
exec(s[:s.index('results={}')])
cases=[('two_bump_default',[],48),
       ('two_bump_short',['unitsDeep=1','overrideBackHeight=true','customBackHeight=30'],48),
       ('two_bump_clearance',['railEndClearance=4'],50),
       ('two_bump_quick',['slotQuickRelease=true'],48),
       ('legacy_four_bump',['pegboardRailLock=false'],45),
       ('two_bump_no_base',['removeBase=true'],48)]
for name,defs,height in cases:
    p,r=run(name,defs)
    assert r.returncode==0 and 'WARNING:' not in r.stderr and 'ERROR:' not in r.stderr
    m=mesh_check(p)
    assert abs(m['size'][2]-height)<.001
    if name=='two_bump_default': (ROOT/'MultiConnect_Multibin.stl').write_bytes(p.read_bytes())
    if name=='two_bump_no_base': (ROOT/'MultiConnect_Multibin_No_Base.stl').write_bytes(p.read_bytes())
p,r=run('bad_rail_clearance',['railEndClearance=-1'])
assert 'ERROR: Assertion' in r.stderr
# The print-tested bin base must remain unchanged by this mounting-only change.
import numpy as np
dt=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')])
for name,defs,old in [('base_unchanged',['baseOnly=true'],'Multibin_Base_Fit_Test.stl'),
                       ('grid_unchanged',['baseOnly=true','removeBase=true'],'Multibin_Ridge_Only_Fit_Test.stl')]:
    p,r=run(name,defs)
    assert r.returncode==0
    a=np.fromfile(p,dtype=dt,offset=84)['v'];b=np.fromfile(ROOT/old,dtype=dt,offset=84)['v']
    assert len(a)==len(b) and np.array_equal(np.unique(a.reshape(-1,3),axis=0),np.unique(b.reshape(-1,3),axis=0))
print('Rail options and unchanged bin-base geometry verified.',flush=True)
