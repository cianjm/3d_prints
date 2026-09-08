from pathlib import Path
import numpy as np

source = Path(r'E:\OneDrive\My Actual Documents\3D Printer\Slide regular.stl')
root = Path(__file__).parent
tri = np.fromfile(source, dtype=np.dtype([('normal','<f4',(3,)),('v','<f4',(3,3)),('attr','<u2')]), offset=84)['v']
points, inverse = np.unique(tri.reshape(-1,3), axis=0, return_inverse=True)
faces = inverse.reshape(-1,3)
edges = np.sort(np.concatenate([faces[:,[0,1]],faces[:,[1,2]],faces[:,[2,0]]]),axis=1)
_, counts = np.unique(edges,axis=0,return_counts=True)
print('Original mesh:',len(points),'vertices;',len(faces),'faces; edge incidences:',np.unique(counts,return_counts=True))
header = '''// Picture hanger with one moving notch and a full-width reinforced extension.
// Units: mm. The original coordinate system is retained.
// Positive extra_hook_reach moves the notch toward NEGATIVE Z.
// Zero returns the original STL exactly, including the notch position.
// The mesh is embedded; no external STL is required.

/* [Hook reach] */
// Notch displacement from its ORIGINAL position, in mm.
extra_hook_reach = 10; // [0:0.5:10]

/* [Reinforcement] */
reinforcement = true;

/* [Hidden] */
hook_width = 16.799995;
hook_end_y = 4.898758;
assert(extra_hook_reach >= 0, "Extra hook reach must be non-negative");

module original_part() {
    polyhedron(points=mesh_points, faces=mesh_faces, convexity=10);
}

// Full-width straight-sided end block. The front is Y=0 throughout;
// both sides align with the original X=0 and X=16.8 faces.
// Small edge rounds do not create a tapered or inset extension.
module hook_blank() {
    r = 0.2;
    translate([r,r,-extra_hook_reach+r])
        minkowski() {
            cube([hook_width-2*r,hook_end_y-2*r,
                  4.5+extra_hook_reach-2*r]);
            sphere(r=r,$fn=24);
        }
}

// Rounded V profile measured from the original STL's centre section.
// Its root is at Y=2.3550568, Z=2.2939341 before displacement.
// The opening extends outside the front face to avoid a closed internal void.
module moving_notch() {
    translate([-1,0,-extra_hook_reach]) rotate([90,0,90])
        linear_extrude(height=hook_width+2,convexity=4)
            polygon([
                [-1,-0.228],
                [2.2806091,2.0961311],
                [2.3211517,2.1554101],
                [2.3464508,2.2226281],
                [2.3550568,2.2939341],
                [2.3464508,2.3652401],
                [2.3211517,2.4324591],
                [2.2806091,2.4917381],
                [-1,4.816]
            ]);
}

// Ribs attach to the opposite face, behind the notch, and grow with reach.
// Straight triangular profiles: no rounded toes at the main-body junction.
// The base overlaps the body by 0.1 mm for a solid connection.
module reinforcing_rib(x) {
    translate([x,0,0]) mirror([0,0,1]) rotate([90,0,90])
        linear_extrude(height=2.8,convexity=4)
            polygon([
                [4.5,-0.1],
                [4.5,extra_hook_reach],
                [4.5+min(9.5,extra_hook_reach),-0.1]
            ]);
}

if (extra_hook_reach == 0) original_part();
else difference() {
    union() {
        // The original body remains; the blank fills the old notch and
        // joins the original end to the extension with flush outer faces.
        original_part();
        hook_blank();
        if (reinforcement) {
            reinforcing_rib(2.8);
            reinforcing_rib(11.2);
        }
    }
    moving_notch();
}

// Original mesh data. OpenSCAD uses the opposite face winding to STL.
'''
with (root/'Adjustable_Picture_Hook.scad').open('w') as f:
    f.write(header)
    f.write('mesh_points = [\n')
    f.write(',\n'.join('['+','.join(format(float(x),'.9g') for x in p)+']' for p in points))
    f.write('\n];\nmesh_faces = [\n')
    f.write(',\n'.join('['+','.join(str(int(x)) for x in face[::-1])+']' for face in faces))
    f.write('\n];\n')
