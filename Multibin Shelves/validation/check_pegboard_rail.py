from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parent.parent
SCAD='C:/Program Files/OpenSCAD/openscad.com'
REF='E:/OneDrive/My Actual Documents/3D Printer/Multibuild/Board Connections/Pegboard Click - Multipoint Rail (Supported).stl'
model=(ROOT/'MultiConnect_Multibin.scad').read_text()
assembly='translate([-totalWidth/2,-totalDepth/2,0]) shelf();'
# Rail is supplied lying on its side: rail face at X=-3, neck at X=0;
# rail width spans Z=0..14.8, end centres at Y=0 and -25.
# Place its wide face 0.2 mm away from the slot's inner plane (-2.35).
# Therefore attachment X=0 maps to Y=-5.55 in the shelf's local frame.
attachment='''multmatrix([[0,0,1,-7.4],[-1,0,0,-totalDepth/2-5.55+railSlotInset+slotDepthMicroadjustment],[0,1,0,backHeight-Multiconnect_Stop_Distance_From_Back],[0,0,0,1]])
    difference() {
        import("'''+REF+'''");
        // Remove only the pre-modelled support projecting beyond rail face X=-3.
        translate([-100,-100,-100]) cube([96.9999,200,100.601]);
    }'''
for name,mode in [('multipoint','Multipoint'),('inch','Multipoint - 1 inch Pegboard')]:
    p=ROOT/'validation'/f'rail_check_{name}.scad'
    p.write_text(model.replace(assembly,'intersection() {\n'+assembly+'\n'+attachment+'\n}'))
    result=subprocess.run([SCAD,'-o',str(p.with_suffix('.stl')),'--export-format','binstl','-D',f'Connection_Type="{mode}"',str(p)],capture_output=True,text=True)
    log=result.stdout+result.stderr
    p.with_suffix('.log').write_text(log)
    print(name,log,flush=True)
    assert 'Current top level object is empty' in log
preview=ROOT/'validation'/'rail_assembly.scad'
preview.write_text(model.replace(assembly,assembly+'\ncolor([0.2,0.6,0.9]) '+attachment))
subprocess.run([SCAD,'-o',str(preview.with_suffix('.png')),'--imgsize=1100,850','--camera=0,0,0,65,0,30,300','--autocenter','--viewall',str(preview)],check=True)


