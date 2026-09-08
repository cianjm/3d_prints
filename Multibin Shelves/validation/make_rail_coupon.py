from pathlib import Path
import subprocess
root=Path(__file__).resolve().parent.parent
s=(root/'MultiConnect_Multibin.scad').read_text()
s=s.replace('unitsWide = 2;','unitsWide = 1;')
s=s.replace('translate([-totalWidth/2,-totalDepth/2,0]) shelf();',
    'translate([-totalWidth/2,-backHeight/2,epsilon]) rotate([-90,0,0]) makebackPlate(totalWidth,backHeight,distanceBetweenSlots,backThickness);')
p=root/'validation'/'Pegboard_Rail_Fit_Coupon.scad'
p.write_text(s)
subprocess.run(['C:/Program Files/OpenSCAD/openscad.com','-o',str(root/'Pegboard_Rail_Fit_Coupon.stl'),'--export-format','binstl',str(p)],check=True)
