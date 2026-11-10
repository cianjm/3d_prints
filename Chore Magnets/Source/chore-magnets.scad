// Toilet chore magnet: print flat with the icon facing up.
// Dimensions are in mm. The back recess is intended for a 6 x 2 mm disc magnet; test the fit.

/* [Tile] */
tile_size = 20;          // Size of upstairs and downstairs tiles
small_tile_size = 16;    // Size of attic and shed tiles
tile_thickness = 10;
corner_radius = 2;
icon_height = 0.8;       // Raised above the front face
icon_size = 15.5;          // Overall width of the icon

/* [Chore] */
chore = "Attic bathroom"; // [Attic bathroom,Shed toilet,Downstairs bathroom,Upstairs bathroom]
label_height = 0.6;      // Raised lettering height
label_font = "Arial:style=Bold"; // Requires Arial installed for regenerating the model
label_size = 3.6;

/* [Magnet] */
magnet_diameter = 6;    // Actual nominal disc diameter
magnet_thickness = 2;    // Actual nominal disc thickness
pocket_diameter_clearance = 0.05; // Total diameter clearance; test the fit
pocket_depth_clearance = 0.1;    // Extra depth to keep magnet below the back

/* [Hidden] */
eps = 0.02;
effective_tile_size = (chore == "Attic bathroom" || chore == "Shed toilet") ? small_tile_size : tile_size;
front_scale = effective_tile_size / 36;
pocket_diameter = magnet_diameter + pocket_diameter_clearance;
pocket_depth = magnet_thickness + pocket_depth_clearance;
notch_width = 1.6; // Screwdriver slot width
notch_extension = 1.2; // Distance beyond the round pocket
pocket_spacing = 9.4; // Centre-to-centre spacing for two-magnet tiles
$fa = 4;
$fs = 0.35;

assert(tile_size >= 20 && small_tile_size >= 16, "Larger tiles must be at least 20 mm and smaller tiles at least 16 mm.");
assert(label_height > 0 && label_size > 0 && label_size <= 3.6, "Use positive lettering height and a label size up to 3.6 mm.");
assert(tile_size > 0 && tile_thickness > 0 && icon_height > 0, "Tile and icon dimensions must be positive.");
assert(corner_radius >= 0 && corner_radius < effective_tile_size/2, "Corner radius must be less than half the tile size.");
assert(icon_size > 0 && icon_size <= 34, "Icon must fit inside the tile with a margin.");
assert(magnet_diameter > 0 && magnet_thickness > 0 && pocket_diameter_clearance >= 0 && pocket_depth_clearance >= 0, "Magnet dimensions must be positive and clearances nonnegative.");
assert(pocket_diameter < effective_tile_size - 2*corner_radius, "Magnet pocket is too wide for the tile.");
assert(effective_tile_size == small_tile_size || pocket_spacing/2 + pocket_diameter/2 < effective_tile_size/2 - corner_radius, "Two magnet pockets must stay inside the tile.");
assert(pocket_depth <= tile_thickness - 0.8, "Increase tile thickness to leave at least 0.8 mm above the magnet pocket.");

// The slot joins the circular pocket while preserving most of its rim.
module magnet_pocket(x) {
    dir = x > 0 ? -1 : 1; // Two pockets face inward; single pocket faces right.
    translate([x,0,-eps]) union() {
        cylinder(h=pocket_depth+eps, d=pocket_diameter);
        translate([dir*(pocket_diameter/2-0.5+notch_extension/2),0,(pocket_depth+eps)/2])
            cube([notch_extension+1,notch_width,pocket_depth+eps],center=true);
    }
}
assert(notch_width>0 && notch_extension>0, "The screwdriver notch must have positive dimensions.");
assert(pocket_spacing - pocket_diameter - 2*notch_extension > 0.6, "Leave at least 0.6 mm between the two slots.");

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

// Arial Bold is installed on the design machine. OpenSCAD needs this font
// to regenerate identical text; the exported STL files contain the lettering.
module label_line(message, y, size=label_size) {
    translate([0, y, tile_thickness-eps])
        linear_extrude(height=label_height+eps)
            text(message, size=size, font=label_font, halign="center", valign="baseline", $fn=24);
}
module labels() {
    line1 = chore == "Attic bathroom" ? "ATTIC" : chore == "Shed toilet" ? "SHED" :
            chore == "Downstairs bathroom" ? "DOWNSTAIRS" : "UPSTAIRS";
    line2 = chore == "Shed toilet" ? "TOILET" : "BATHROOM";
    // Keep both lines the same size, aiming at 2 mm actual capital height.
    // The long bathroom label on a 16 mm tile uses 1.8 mm to preserve margins.
    target_text_height = effective_tile_size == small_tile_size && chore == "Attic bathroom" ? 1.8 : 2.0;
    local_size = target_text_height / (1.028*front_scale);
    label_line(line1, -0.285*effective_tile_size/front_scale, local_size);
    label_line(line2, -0.445*effective_tile_size/front_scale, local_size);
}

// Each location has a distinctive pictogram beside the toilet.
module location_symbol() {
    if (chore == "Attic bathroom") {
        // Roof outline, floor and small loft window.
        difference() {
            polygon([[-6,-2], [0,5.5], [6,-2], [6,-5], [-6,-5]]);
            polygon([[-4.6,-2.4], [0,3.4], [4.6,-2.4], [4.6,-3.6], [-4.6,-3.6]]);
        }
        translate([0,-0.5]) circle(d=2.2);
        translate([-6,-3.7]) square([12,1.1]);
    } else if (chore == "Shed toilet") {
        // Shed with pitched roof, side walls and a door.
        polygon([[-6,1], [0,5.5], [6,1], [6,-5], [-6,-5]]);
        translate([-4.7,-3.8]) square([9.4,4.6]); // fused to silhouette
        // Door and window are cut out in the 2D shape below instead.
    } else {
        // Stair steps and an arrow indicating direction of travel.
        polygon([[-6,-5],[-6,-3.8],[-3.6,-3.8],[-3.6,-1.8],[-1.2,-1.8],
                 [-1.2,0.2],[1.2,0.2],[1.2,2.2],[3.6,2.2],[3.6,4.2],
                 [5.5,4.2],[5.5,3],[4.8,3],[4.8,1],[2.4,1],[2.4,-1],
                 [0,-1],[0,-3],[-2.4,-3],[-2.4,-5]]);
        if (chore == "Upstairs bathroom")
            polygon([[-4.8,1],[-4.8,4.2],[-6,4.2],[-4.1,6.2],[-2.2,4.2],[-3.4,4.2],[-3.4,1]]);
        else
            polygon([[3.1,-1.8],[3.1,-4.2],[1.9,-4.2],[3.8,-6.2],[5.7,-4.2],[4.5,-4.2],[4.5,-1.8]]);
    }
}
module shed_symbol() {
    difference() {
        polygon([[-6,1], [0,5.5], [6,1], [6,-5], [-6,-5]]);
        translate([-1.8,-5-eps]) square([3.6,5.1]);
        translate([-4.4,0.4]) square([2.1,1.8]);
    }
}
module raised_location() {
    translate([8,5.8,tile_thickness-eps])
        linear_extrude(height=icon_height+eps)
            if (chore == "Shed toilet") shed_symbol(); else location_symbol();
}

assert(chore == "Attic bathroom" || chore == "Shed toilet" || chore == "Downstairs bathroom" || chore == "Upstairs bathroom", "Select one of the four chore names.");

union() {
    difference() {
        linear_extrude(height=tile_thickness) rounded_square(effective_tile_size, corner_radius);
        for (x = chore == "Downstairs bathroom" || chore == "Upstairs bathroom" ? [-pocket_spacing/2, pocket_spacing/2] : [0])
            magnet_pocket(x);
    }
    scale([front_scale,front_scale,1]) {
        translate([-8,5.8,tile_thickness-eps])
            linear_extrude(height=icon_height+eps) toilet_icon();
        labels();
        raised_location();
    }
}
