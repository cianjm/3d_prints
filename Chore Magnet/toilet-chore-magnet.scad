// Toilet chore magnet: print flat with the icon facing up.
// Dimensions are in mm. The back recess is intended for a glued-in disc magnet.

/* [Tile] */
tile_size = 32;          // Square width and height
tile_thickness = 3.2;
corner_radius = 2;
icon_height = 0.8;       // Raised above the front face
icon_size = 23;          // Overall width of the icon

/* [Magnet] */
magnet_diameter = 10;    // Actual nominal disc diameter
magnet_thickness = 2;    // Actual nominal disc thickness
pocket_diameter_clearance = 0.3; // Total diameter clearance, for glue
pocket_depth_clearance = 0.1;    // Extra depth to keep magnet below the back

/* [Hidden] */
eps = 0.02;
pocket_diameter = magnet_diameter + pocket_diameter_clearance;
pocket_depth = magnet_thickness + pocket_depth_clearance;
$fa = 4;
$fs = 0.35;

assert(tile_size > 0 && tile_thickness > 0 && icon_height > 0, "Tile and icon dimensions must be positive.");
assert(corner_radius >= 0 && corner_radius < tile_size/2, "Corner radius must be less than half the tile size.");
assert(icon_size > 0 && icon_size <= tile_size - 2, "Icon must fit inside the tile with a margin.");
assert(magnet_diameter > 0 && magnet_thickness > 0 && pocket_diameter_clearance >= 0 && pocket_depth_clearance >= 0, "Magnet dimensions must be positive and clearances nonnegative.");
assert(pocket_diameter < tile_size - 2*corner_radius, "Magnet pocket is too wide for the tile.");
assert(pocket_depth <= tile_thickness - 0.8, "Increase tile thickness to leave at least 0.8 mm above the magnet pocket.");

module rounded_square(size, radius) {
    if (radius == 0) square([size, size], center=true);
    else offset(r=radius) square([size-2*radius, size-2*radius], center=true);
}

// The icon uses a 24 x 24 coordinate system and independent raised regions.
module toilet_icon() {
    scale([icon_size/24, icon_size/24]) union() {
        // Cistern and its slightly overhanging lid.
        translate([-10.5, 1.1]) square([6, 11]);
        translate([-10.8, 12.1]) offset(r=0.55) square([6.6, 1.1]);
        // Seat and bowl, with a visible gap between them.
        translate([-3.3, 0.9]) offset(r=0.5) square([14.0, 0.55]);
        polygon(points=[[-4.2,0], [11,0], [10.8,-2.0], [10.1,-3.8],
            [8.8,-5.4], [7,-6.6], [5.6,-7.2], [5.6,-10.7],
            [-3,-10.7], [-3,-7.2], [-4.6,-6.5], [-6,-5.3],
            [-7.1,-3.8], [-7.8,-2], [-8,0]]);
        // Foot of the pedestal.
        translate([-3.6,-12.4]) offset(r=0.55) square([9.8,0.75]);
    }
}

union() {
    difference() {
        linear_extrude(height=tile_thickness) rounded_square(tile_size, corner_radius);
        translate([0,0,-eps]) cylinder(h=pocket_depth+eps, d=pocket_diameter);
    }
    translate([0,0,tile_thickness-eps])
        linear_extrude(height=icon_height+eps) toilet_icon();
}
