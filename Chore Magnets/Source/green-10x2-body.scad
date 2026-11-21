// Configurable chore-tile body for one removable 10 x 2 mm disc magnet.
// The 0.05 mm diametral and 0.1 mm depth clearances reuse the 6 mm fit
// as a starting point; the 10 mm magnet fit has not yet been tested.
tile_size = 20;
tile_thickness = 10;
corner_radius = 1.6; // use 2 for bathroom and attic-hoover tiles
magnet_diameter = 10;
magnet_thickness = 2;
pocket_diameter_clearance = 0.05;
pocket_depth_clearance = 0.1;
notch_width = 1.6;
notch_extension = 1.2;
eps = 0.02;
pocket_d = magnet_diameter + pocket_diameter_clearance;
pocket_depth = magnet_thickness + pocket_depth_clearance;
$fa = 4; $fs = 0.25;
assert(tile_size > 2*corner_radius && corner_radius > 0, "Check tile size and corner radius.");
assert(pocket_d/2 + notch_extension < tile_size/2-corner_radius, "Magnet pocket or removal notch is too close to the edge.");
assert(pocket_depth > 0 && pocket_depth < tile_thickness - 0.8, "Check magnet and tile thickness.");
difference() {
 linear_extrude(height=tile_thickness) offset(r=corner_radius) square([tile_size-2*corner_radius,tile_size-2*corner_radius],center=true);
 translate([0,0,-eps]) union() {
  cylinder(d=pocket_d,h=pocket_depth+eps);
  translate([pocket_d/2-0.5+notch_extension/2,0,(pocket_depth+eps)/2]) cube([notch_extension+1,notch_width,pocket_depth+eps],center=true);
 }
}
