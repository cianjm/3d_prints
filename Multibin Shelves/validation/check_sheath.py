from pathlib import Path
import subprocess
ROOT=Path.cwd(); SCAD='C:/Program Files/OpenSCAD/openscad.com'
s=Path('validation/check_pegboard_rail.py').read_text();exec(s[:s.index('for name,mode')].replace('ROOT=Path(__file__).resolve().parent.parent','ROOT=Path.cwd()'))
old=Path('validation/before_rail_snug.scad').read_text()
sheath='multmatrix([[1,0,0,0],[0,0,-1,-totalDepth/2-2.37],[0,1,0,backHeight-Multiconnect_Stop_Distance_From_Back-34.5],[0,0,0,1]]) import("'+(ROOT/'Pegboard_Rail_Sheath.stl').as_posix()+'");'
for name,other in [('shelf',assembly),('rail',attachment)]:
 p=ROOT/'validation'/('sheath_check_'+name+'.scad');p.write_text(old.replace(assembly,'intersection(){'+sheath+other+'}'))
 r=subprocess.run([SCAD,'-o',str(p.with_suffix('.stl')),str(p)],capture_output=True,text=True);log=r.stdout+r.stderr;p.with_suffix('.log').write_text(log);assert 'Current top level object is empty' in log,log
 print(name,'no collision',flush=True)
p=ROOT/'validation/sheath_assembly.scad';p.write_text(old.replace(assembly,'color("orange") '+sheath+'color("steelblue") '+attachment))
subprocess.run([SCAD,'-o',str(p.with_suffix('.png')),'--imgsize=1000,750','--autocenter','--viewall',str(p)],check=True)
__file__=str(ROOT/'validation/check_model.py');s=Path(__file__).read_text();exec(s[:s.index('results={}')])
mesh_check(ROOT/'Pegboard_Rail_Sheath.stl')
for name,defs in [('sheath_thinner',['shimDepth=0.6']),('sheath_tighter',['railClearance=0.05']),('sheath_invalid',['railClearance=0.5'])]:
 p,r=run(name,defs,source=ROOT/'Pegboard_Rail_Sheath.scad')
 if name=='sheath_invalid':assert 'ERROR: Assertion' in r.stderr
 else: assert r.returncode==0;mesh_check(p)

