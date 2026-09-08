from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parent.parent
SCAD='C:/Program Files/OpenSCAD/openscad.com'
REF='E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Board Connections/Pegboard Click - Multipoint Rail (Supported).stl'
s=(ROOT/'MultiConnect_Multibin.scad').read_text()
assembly='translate([-totalWidth/2,-totalDepth/2,0]) shelf();'
call='yMultipointSlotDimples(z, slotBaseRadius, distanceBetweenSlots, distanceOffset);'
# Validation-only: keep the upper two bumps at the top catch point.
s=s.replace(call,'intersection() { '+call+' translate([-20,-20,0]) cube([40,40,100]); }')
attachment='''multmatrix([[0,0,1,-7.4],[-1,0,0,-totalDepth/2-5.55],[0,1,0,32],[0,0,0,1]])
    difference() {
        import("'''+REF+'''");
        translate([-100,-100,-100]) cube([96.9999,200,100.601]);
    }'''
p=ROOT/'validation'/'two_bump_intersection.scad'
p.write_text(s.replace(assembly,'intersection() {\n'+assembly+'\n'+attachment+'\n}'))
r=subprocess.run([SCAD,'-o',str(p.with_suffix('.stl')),'--export-format','binstl',str(p)],capture_output=True,text=True)
log=r.stdout+r.stderr
p.with_suffix('.log').write_text(log)
print(log,flush=True)
