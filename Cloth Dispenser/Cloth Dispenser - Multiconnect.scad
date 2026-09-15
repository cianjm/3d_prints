// Cloth dispenser remix: dust-reduced front opening + Multiconnect V2 rails.
//
// Source body: "Cloth Dispenser.stl" supplied alongside this file.
// Multiconnect V2 interface dimensions by David D, CC BY 4.0:
// https://makerworld.com/en/models/645768-multiconnect-v2-modeling-files
//
// Units: millimetres.

/* [Front opening] */
opening_radius = 20;        // Radius of the upper semicircular finger opening.
horizontal_slot_top = 22;  // Measured top edge of the original horizontal slot.
horizontal_slot_bottom = 10; // Measured bottom edge of the original horizontal slot.
front_connection_bottom = 18; // Overlap into the original slot to remove the bridge.

/* [Multiconnect mount] */
mount_enabled = true;
mount_channel_count = 3;   // Number of rear Multiconnect receiver slots.
mount_channel_spacing = 25; // Multiconnect / Multiboard grid pitch.
mount_bottom = 0;           // Channels remain open at the bottom for installation.
mount_top = 210;            // Rounded channel crown; leaves 10 mm of wall above.

/* [Quality] */
curve_fn = 72;

// Measured source-mesh references. Do not change unless replacing the source STL.
body_x_min = 86;
body_x_max = 170;
body_y_front = 58.6583;
body_y_back = 122.6583;
body_z_max = 220;
front_wall = 2;
old_vertical_slot_x_min = 118;
old_vertical_slot_x_max = 138;
old_vertical_slot_top = 110;
old_horizontal_slot_x_min = 88;
old_horizontal_slot_x_max = 168;

// Published Multiconnect V2 receiver profile.
mc_receiver_width = 20.3;
mc_receiver_half_width = mc_receiver_width / 2;
mc_receiver_depth = 4.15;
mc_mouth_half_width = 7.65; // 15 mm connector stem + 0.15 mm per side.
mc_mouth_depth = 0.4379;
mc_ramp_depth = 2.5;
mc_inner_lip_depth = 1.2121;

// Thicken the rear wall inward, keeping the original outside face flush.
mount_backing = 2;
mount_plate_depth = mc_receiver_depth + mount_backing;
mount_channel_array_width = (mount_channel_count - 1) * mount_channel_spacing
                            + mc_receiver_width;
// Run the thickened inner back plane from side wall to side wall so there are
// no unnecessary internal steps beside the Multiconnect receiver array.
mount_plate_width = body_x_max - body_x_min;
body_center_x = (body_x_min + body_x_max) / 2;
mount_outer_y = body_y_back;
eps = 0.02;

assert(opening_radius > 0, "opening_radius must be positive.");
assert(2 * opening_radius < body_x_max - body_x_min - 2,
       "opening_radius leaves too little front wall at the sides.");
assert(horizontal_slot_top + opening_radius < body_z_max,
       "The semicircular opening extends beyond the body height.");
assert(front_connection_bottom < horizontal_slot_top && front_connection_bottom >= 0,
       "front_connection_bottom must overlap below horizontal_slot_top.");
assert(horizontal_slot_bottom < front_connection_bottom,
       "horizontal_slot_bottom must be below the front connection.");
assert(mount_channel_spacing >= mc_receiver_width,
       "Mount channels overlap; increase mount_channel_spacing.");
assert(mount_channel_count >= 1 && mount_channel_count == floor(mount_channel_count),
       "mount_channel_count must be a positive whole number.");
assert(mount_channel_array_width + 5 <= mount_plate_width,
       "The mount array is too wide for the dispenser back.");
assert(mount_bottom >= 0 && mount_top <= body_z_max && mount_top > mount_bottom,
       "Mount rail limits must remain within the dispenser height.");
assert(body_z_max - mount_top >= mount_backing,
       "Leave enough solid wall above the rounded channel tops.");

module source_body() {
    import("Cloth Dispenser.stl", convexity = 10);
}

// Replaces the original 20 mm-wide, tall front slot with solid wall material.
module old_slot_filler() {
    translate([
        old_vertical_slot_x_min - eps,
        body_y_front,
        horizontal_slot_top - eps
    ])
        cube([
            old_vertical_slot_x_max - old_vertical_slot_x_min + 2 * eps,
            front_wall,
            old_vertical_slot_top - horizontal_slot_top + 2 * eps
        ]);
}

// Closes the outer portions of the original 80 mm-wide lower slot so its
// remaining opening aligns exactly with the 40 mm semicircle above it.
module horizontal_slot_side_fillers() {
    opening_left = body_center_x - opening_radius;
    opening_right = body_center_x + opening_radius;

    translate([
        old_horizontal_slot_x_min - eps,
        body_y_front,
        horizontal_slot_bottom - eps
    ])
        cube([
            opening_left - old_horizontal_slot_x_min + eps,
            front_wall,
            horizontal_slot_top - horizontal_slot_bottom + 2 * eps
        ]);

    translate([
        opening_right,
        body_y_front,
        horizontal_slot_bottom - eps
    ])
        cube([
            old_horizontal_slot_x_max - opening_right + eps,
            front_wall,
            horizontal_slot_top - horizontal_slot_bottom + 2 * eps
        ]);
}

module semicircular_front_cutout() {
    union() {
        intersection() {
            translate([body_center_x, body_y_front + front_wall + eps, horizontal_slot_top])
                rotate([90, 0, 0])
                    cylinder(h = front_wall + 2 * eps, r = opening_radius, $fn = curve_fn);

            // Retain only the half-circle rising above the horizontal slot.
            translate([
                body_center_x - opening_radius - eps,
                body_y_front - eps,
                horizontal_slot_top
            ])
                cube([
                    2 * opening_radius + 2 * eps,
                    front_wall + 2 * eps,
                    opening_radius + eps
                ]);
        }

        // Deliberately overlaps the existing horizontal opening, eliminating
        // the thin bar that otherwise remains between the two cutouts.
        translate([
            body_center_x - opening_radius - eps,
            body_y_front - eps,
            front_connection_bottom
        ])
            cube([
                2 * opening_radius + 2 * eps,
                front_wall + 2 * eps,
                horizontal_slot_top - front_connection_bottom + eps
            ]);
    }
}

module mount_plate() {
    translate([
        body_center_x - mount_plate_width / 2,
        body_y_back - mount_plate_depth,
        0
    ])
        cube([mount_plate_width, mount_plate_depth, body_z_max]);
}

// 2D vertical slot with an open bottom and a semicircular closed crown.
// All profile layers share mount_top as their highest point.
module rounded_top_slot_2d(width) {
    radius = width / 2;
    crown_center_z = mount_top - radius;

    union() {
        translate([-radius, mount_bottom - eps])
            square([width, crown_center_z - mount_bottom + eps]);
        translate([0, crown_center_z])
            circle(r = radius, $fn = curve_fn);
    }
}

// A thin slot-profile slice extruded inward from a specified rear Y position.
module receiver_slice(center_x, rear_y, width, thickness = eps) {
    translate([center_x, rear_y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness)
                rounded_top_slot_2d(width);
}

// Negative profile from the published Multiconnect V2 back-slot drawing.
// The mouth is flush with the original rear plane. The dovetail cavity expands
// inward and terminates in a rounded top so the dispenser cannot slide through.
module multiconnect_receiver_cut(center_x) {
    mouth_width = 2 * mc_mouth_half_width;
    mouth_inner_y = mount_outer_y - mc_mouth_depth;
    ramp_inner_y = mouth_inner_y - mc_ramp_depth;

    union() {
        // Straight mouth layer.
        translate([center_x, mount_outer_y + eps, 0])
            rotate([90, 0, 0])
                linear_extrude(height = mc_mouth_depth + 2 * eps)
                    rounded_top_slot_2d(mouth_width);

        // 45-degree dovetail transition, including the rounded crown.
        hull() {
            receiver_slice(center_x, mouth_inner_y + eps, mouth_width);
            receiver_slice(center_x, ramp_inner_y, mc_receiver_width);
        }

        // Full-width inner pocket and lip clearance.
        translate([center_x, ramp_inner_y + eps, 0])
            rotate([90, 0, 0])
                linear_extrude(height = mc_inner_lip_depth + 2 * eps)
                    rounded_top_slot_2d(mc_receiver_width);
    }
}

module modified_dispenser() {
    difference() {
        union() {
            source_body();
            old_slot_filler();
            horizontal_slot_side_fillers();
            if (mount_enabled)
                mount_plate();
        }

        semicircular_front_cutout();

        if (mount_enabled)
            for (channel_index = [0 : mount_channel_count - 1])
                multiconnect_receiver_cut(
                    body_center_x
                    + (channel_index - (mount_channel_count - 1) / 2)
                    * mount_channel_spacing
                );
    }
}

modified_dispenser();
