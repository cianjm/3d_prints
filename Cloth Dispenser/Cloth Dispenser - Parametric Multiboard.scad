// Parametric microfiber-cloth dispenser for the 25 mm Multiboard grid.
//
// The body is generated entirely from OpenSCAD primitives. Width, depth, and
// height are specified in Multiboard units; one unit is one 25 mm grid pitch.
// The rear Multiconnect V2 receiver count follows width_units automatically.
//
// Multiconnect V2 interface dimensions by David D, CC BY 4.0:
// https://makerworld.com/en/models/645768-multiconnect-v2-modeling-files

/* [Overall size in Multiboard units] */
width_units = 3;  // [2:1:8]
depth_units = 3;  // [2:1:8]
height_units = 5; // [3:1:16]

/* [Part to render] */
//Set which render to show.
part_to_render = "print_layout"; // [print_layout:Body and lid side-by-side, body: Main body with no lid, lid: Lid with no body, assembly_preview: Lid slotted into the main body]

/* [Body and opening] */
//Thickness (mm) of the vertical walls
wall_thickness = 2;       // [1.2:0.2:4]
//Thickness (mm) of the bottom of the bin
bottom_thickness = 2;     // [1.2:0.2:4]
//Fillet applied to front vertical edges.
front_edge_radius = 3;    // [0:0.5:10]
// The radius (mm) of the semi-circular hole at the bottom of the front wall
opening_radius = 20;      // [15:1:30]
// How high (mm) the semi-circular hole should rise above the floor of the model.
horizontal_slot_top = 5; // [1:1:35]
// Radius (mm) of semi-circular opening at the bottom of the model.
bottom_relief_radius = 10; // [5:1:15]

/* [Multiconnect mount] */
// Enable or disable the multiconnect slots on the back of the main body.
mount_enabled = true;
// Solid wall above the rounded channel crowns.
mount_top_margin = 10;
// Material remaining behind the receiver cavity.
mount_backing = 2;

/* [Sliding lid] */

// Thickness (mm) of the main body of the lid.
lid_top_thickness = 2; // [1.2:0.2:3]

// Depth (mm) of the left, right, and rear lid grooves. Their roofs and the matching lid edges use 45-degree chamfers of this size. Must be smaller than `wall_thickness`.
lid_groove_depth = 0.8; // [0.6:0.1:1.2]

// Thickness (mm) of the main body rails above the sliding lid edges; also controls the raised lid panel height.
lid_top_retainer = 1.6;      // [1.2:0.2:3]

// Depth (mm) of the pull tab.
lid_handle_depth = 5;        // [5:1:15]

// Radius (mm) of the fillets on the pull tab.
lid_handle_fillet_radius = 2; // [0:0.5:4]

// Height (mm) of the ramped retention bump under the lid; set to 0 to disable it.
lid_detent_height = 0.4; // [0:0.05:0.6]

/* [Lid Tolerances] */
// Clearance (mm) on each left/right edge of the lid. Higher value will make lid looser, lower will make it tigher. Scales only lid itself, not the grooves on the body.
lid_side_clearance = 0.2; // [0.1:0.05:0.5]


// Clearance (mm) above/below the lid in the grooves. Higher value will make the lid looser, lower will make it tigher. Scales only the grooves on the main body, not the thickness of the lid.
lid_vertical_clearance = 0.3; // [0.2:0.1:0.8]


// Clearance (mm) between the rear of the lid and the wall of the groove it slides into. If the lid is not sliding all the way back, try increasing this value. If the lid seems loose at the back, try decrease it. Scales only lid, not the main body, so can re-print just the lid to get the right fit.
lid_rear_clearance = 0.2;    // [0.1:0.1:0.6]

/* [Quality] */
// Decrease for faster renders, increase for smoother curves on model.
curve_fn = 72; // [36:12:120]

/* [Hidden] */
grid_unit = 25;
outer_width = width_units * grid_unit;
outer_depth = depth_units * grid_unit;
outer_height = height_units * grid_unit;
body_center_x = outer_width / 2;
front_wall = wall_thickness;

// Published Multiconnect V2 receiver profile.
mc_receiver_width = 20.3;
mc_receiver_depth = 4.15;
mc_mouth_half_width = 7.65; // 15 mm stem + 0.15 mm clearance per side.
mc_mouth_depth = 0.4379;
mc_ramp_depth = 2.5;
mc_inner_lip_depth = 1.2121;

mount_channel_count = width_units;
mount_channel_spacing = grid_unit;
mount_channel_array_width = (mount_channel_count - 1) * mount_channel_spacing
                            + mc_receiver_width;
rear_wall_thickness = mc_receiver_depth + mount_backing;
mount_bottom = 0;
mount_top = outer_height - mount_top_margin;
eps = 0.02;

inner_width = outer_width - 2 * wall_thickness;
inner_depth = outer_depth - front_wall - rear_wall_thickness;
rear_inner_y = outer_depth - rear_wall_thickness;
lid_rail_x_min = wall_thickness - lid_groove_depth;
lid_rail_span = inner_width + 2 * lid_groove_depth;
lid_width = lid_rail_span - 2 * lid_side_clearance;
// The rear edge enters a shallow pocket matching the two side-groove depths.
lid_depth = rear_inner_y + lid_groove_depth - lid_rear_clearance;
lid_groove_height = lid_top_thickness + lid_vertical_clearance;
lid_groove_bottom = outer_height - lid_top_retainer - lid_groove_height;
lid_groove_top = lid_groove_bottom + lid_groove_height;
lid_assembled_z = lid_groove_bottom + lid_vertical_clearance / 2;
lid_front_radius = min(front_edge_radius, lid_width / 2 - eps);
inner_front_radius = max(front_edge_radius - wall_thickness, 0);
lid_handle_target_width = 0.8 * lid_width;
lid_handle_fillet_width = lid_width
                          - 2 * (lid_front_radius
                                 + lid_handle_fillet_radius);
lid_handle_width = min(lid_handle_target_width, lid_handle_fillet_width);
// Extend the stopper to the rounded corner's tangent plane so its rear face
// still reaches the straight side rails. The body cutaway uses the same value.
lid_fascia_depth = max(front_wall, lid_front_radius);
lid_flush_top_height = lid_top_retainer + lid_vertical_clearance / 2;
lid_total_height = lid_top_thickness + lid_flush_top_height;
// Centre the retention ridge across 80% of the lid's full outside width.
lid_detent_length = 0.8 * outer_width;
lid_detent_ramp_depth = 1.6;
lid_detent_center_y = lid_fascia_depth + 1;

assert(width_units >= 2 && width_units == floor(width_units),
       "width_units must be a whole number of at least 2.");
assert(depth_units >= 2 && depth_units == floor(depth_units),
       "depth_units must be a whole number of at least 2.");
assert(height_units >= 3 && height_units == floor(height_units),
       "height_units must be a whole number of at least 3.");
assert(front_edge_radius >= 0 && front_edge_radius <= 10,
       "front_edge_radius must be between 0 and 10 mm.");
assert(2 * opening_radius + 2 * wall_thickness < outer_width,
       "The front opening is too wide for this width_units setting.");
assert(2 * (opening_radius + front_edge_radius) < outer_width,
       "Reduce front_edge_radius/opening_radius or increase width_units.");
assert(2 * bottom_relief_radius + 2 * wall_thickness < outer_width,
       "The bottom relief is too wide for this width_units setting.");
assert(front_wall + bottom_relief_radius
       < outer_depth - rear_wall_thickness,
       "The bottom relief is too deep for this depth_units setting.");
assert(horizontal_slot_top + opening_radius < outer_height,
       "The front opening is too tall for this height_units setting.");
assert(inner_depth > 2 * wall_thickness,
       "The selected depth is too small for the front and reinforced rear walls.");
assert(mount_channel_array_width + 4 <= outer_width,
       "The receiver array is too wide for the selected width.");
assert(mount_top > mc_receiver_width / 2,
       "The selected height is too short for the rounded receiver slots.");
assert(lid_groove_depth > 0 && lid_groove_depth < wall_thickness,
       "lid_groove_depth must be smaller than wall_thickness.");
assert(lid_groove_depth <= lid_top_thickness
       && lid_groove_depth <= lid_top_retainer,
       "The 45-degree groove chamfer must fit within the lid and top retainer thicknesses.");
assert(lid_top_retainer > 0 && lid_groove_bottom > horizontal_slot_top,
       "The lid groove leaves insufficient body height below it.");
assert(lid_rear_clearance >= 0
       && lid_rear_clearance < lid_groove_depth,
       "lid_rear_clearance must be smaller than lid_groove_depth.");
assert(lid_handle_width > 2 * lid_handle_fillet_radius
       && lid_width > lid_handle_width && lid_depth > front_wall,
       "The sliding lid dimensions are invalid for this body size.");
assert(lid_handle_fillet_radius >= 0
       && lid_handle_fillet_radius <= lid_handle_depth / 2
       && lid_handle_fillet_radius <= (lid_width - lid_handle_width) / 2,
       "The pull-tab fillet is too large for its depth or side shoulders.");
assert(lid_detent_height >= 0
       && lid_detent_height <= min(0.6, lid_top_thickness / 2),
       "lid_detent_height must be between 0 and half the lid thickness.");

// Rectangle with rounded front corners and square rear corners. Extruding this
// profile creates fillets only on the two front vertical body edges.
module front_rounded_rect_2d(width, depth, radius) {
    if (radius <= 0) {
        square([width, depth]);
    } else {
        union() {
            translate([radius, 0])
                square([width - 2 * radius, depth]);
            translate([0, radius])
                square([width, depth - radius]);
            translate([radius, radius])
                circle(r = radius, $fn = curve_fn);
            translate([width - radius, radius])
                circle(r = radius, $fn = curve_fn);
        }
    }
}

// 2D receiver profile: open at the build plate and closed by a rounded crown.
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

module receiver_slice(center_x, rear_y, width, thickness = eps) {
    translate([center_x, rear_y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness)
                rounded_top_slot_2d(width);
}

// Flush Multiconnect V2 receiver with a rounded closed top.
module multiconnect_receiver_cut(center_x) {
    mouth_width = 2 * mc_mouth_half_width;
    mouth_inner_y = outer_depth - mc_mouth_depth;
    ramp_inner_y = mouth_inner_y - mc_ramp_depth;

    union() {
        translate([center_x, outer_depth + eps, 0])
            rotate([90, 0, 0])
                linear_extrude(height = mc_mouth_depth + 2 * eps)
                    rounded_top_slot_2d(mouth_width);

        hull() {
            receiver_slice(center_x, mouth_inner_y + eps, mouth_width);
            receiver_slice(center_x, ramp_inner_y, mc_receiver_width);
        }

        translate([center_x, ramp_inner_y + eps, 0])
            rotate([90, 0, 0])
                linear_extrude(height = mc_inner_lip_depth + 2 * eps)
                    rounded_top_slot_2d(mc_receiver_width);
    }
}

// Front opening: a full-width cut from the base to horizontal_slot_top, with
// a semicircular arch above it.
module front_opening_cut() {
    cut_depth = front_wall + 2 * eps;

    union() {
        translate([
            body_center_x - opening_radius,
            -eps,
            -eps
        ])
            cube([
                2 * opening_radius,
                cut_depth,
                horizontal_slot_top + 2 * eps
            ]);

        intersection() {
            translate([
                body_center_x,
                front_wall + eps,
                horizontal_slot_top
            ])
                rotate([90, 0, 0])
                    cylinder(h = cut_depth, r = opening_radius, $fn = curve_fn);

            translate([
                body_center_x - opening_radius - eps,
                -eps,
                horizontal_slot_top
            ])
                cube([
                    2 * opening_radius + 2 * eps,
                    cut_depth,
                    opening_radius + eps
                ]);
        }

    }
}

// Original-style lower finger relief in the horizontal XY floor plane. Its
// centre lies on the inner face of the front wall, so the inward-facing half
// is a semicircle while the outer portion opens cleanly through the front.
module bottom_floor_relief_cut() {
    translate([body_center_x, front_wall, -eps])
        cylinder(
            h = bottom_thickness + 2 * eps,
            r = bottom_relief_radius,
            $fn = curve_fn
        );
}

// Support-free 45-degree roof reliefs for the left, right, and rear grooves.
// Each roof grows inward by no more than one groove depth as it rises, avoiding
// a horizontal first layer above any of the three captured lid edges.
module groove_roof_chamfer_cuts() {
    side_y_min = lid_fascia_depth;
    side_y_max = rear_inner_y + lid_groove_depth + eps;
    side_y_span = side_y_max - side_y_min;
    chamfer = lid_groove_depth;

    // Left roof.
    hull() {
        translate([
            lid_rail_x_min - eps,
            side_y_min,
            lid_groove_top - eps
        ])
            cube([
                wall_thickness - lid_rail_x_min + 2 * eps,
                side_y_span,
                eps
            ]);

        translate([
            wall_thickness - eps,
            side_y_min,
            lid_groove_top + chamfer - eps
        ])
            cube([eps, side_y_span, eps]);
    }

    // Right roof.
    hull() {
        translate([
            outer_width - wall_thickness - eps,
            side_y_min,
            lid_groove_top - eps
        ])
            cube([
                wall_thickness - lid_rail_x_min + 2 * eps,
                side_y_span,
                eps
            ]);

        translate([
            outer_width - wall_thickness,
            side_y_min,
            lid_groove_top + chamfer - eps
        ])
            cube([eps, side_y_span, eps]);
    }

    // Rear roof. The rear pocket is deliberately only one groove depth deep,
    // allowing the same 45-degree treatment within the top retainer height.
    hull() {
        translate([
            lid_rail_x_min - eps,
            rear_inner_y - eps,
            lid_groove_top - eps
        ])
            cube([
                lid_rail_span + 2 * eps,
                lid_groove_depth + 2 * eps,
                eps
            ]);

        translate([
            lid_rail_x_min - eps,
            rear_inner_y - eps,
            lid_groove_top + chamfer - eps
        ])
            cube([lid_rail_span + 2 * eps, eps, eps]);
    }
}

// Captured side grooves, an open front entry, and a shallow pocket in the
// reinforced rear wall. Solid material behind the pocket is the insertion stop.
module sliding_lid_channels_cut() {
    // Cut the captured groove from the actual lid outline plus the specified
    // per-side clearance. This gives rounded lids room inside the curved front
    // wall without making the visible top cutaway any deeper.
    translate([0, 0, lid_groove_bottom])
        linear_extrude(height = lid_groove_height + 2 * eps)
            intersection() {
                offset(delta = lid_side_clearance)
                    lid_plate_2d();

                translate([-eps, -eps])
                    square([
                        outer_width + 2 * eps,
                        rear_inner_y + lid_groove_depth + eps
                    ]);
            }

    // The raised stopper enters this full-height cutaway. Its depth is exactly
    // lid_fascia_depth at every front_edge_radius value.
    translate([
        -eps,
        -eps,
        lid_groove_bottom
    ])
        cube([
            outer_width + 2 * eps,
            lid_fascia_depth + eps,
            outer_height - lid_groove_bottom + eps
        ]);

    groove_roof_chamfer_cuts();
}

// The lower shell retains the selected front fillet. Above the groove, the
// two side rails are straight and begin at the same plane as the stopper's
// rear face. This avoids a curled rail and its sharp, unsupported overhang.
module body_outer_blank() {
    union() {
        linear_extrude(height = lid_groove_top + eps)
            front_rounded_rect_2d(
                outer_width,
                outer_depth,
                front_edge_radius
            );

        translate([0, lid_fascia_depth, lid_groove_top - eps])
            cube([
                wall_thickness,
                outer_depth - lid_fascia_depth,
                outer_height - lid_groove_top + eps
            ]);

        translate([
            outer_width - wall_thickness,
            lid_fascia_depth,
            lid_groove_top - eps
        ])
            cube([
                wall_thickness,
                outer_depth - lid_fascia_depth,
                outer_height - lid_groove_top + eps
            ]);

        translate([
            0,
            outer_depth - rear_wall_thickness,
            lid_groove_top - eps
        ])
            cube([
                outer_width,
                rear_wall_thickness,
                outer_height - lid_groove_top + eps
            ]);
    }
}

module dispenser_body() {
    difference() {
        body_outer_blank();

        // Open-top storage cavity. The rear wall is thick enough to contain
        // the flush Multiconnect dovetails across the complete body width.
        // Its front corners follow the outside radius to retain wall thickness.
        translate([wall_thickness, front_wall, bottom_thickness])
            linear_extrude(height = outer_height - bottom_thickness + eps)
                front_rounded_rect_2d(
                    inner_width,
                    inner_depth,
                    inner_front_radius
                );

        front_opening_cut();
        bottom_floor_relief_cut();
        sliding_lid_channels_cut();

        if (mount_enabled)
            for (channel_index = [0 : mount_channel_count - 1])
                multiconnect_receiver_cut(
                    body_center_x
                    + (channel_index - (mount_channel_count - 1) / 2)
                    * mount_channel_spacing
                );
    }
}

module lid_plate_2d() {
    lid_x = body_center_x - lid_width / 2;

    translate([lid_x, 0])
        front_rounded_rect_2d(lid_width, lid_depth, lid_front_radius);
}

function arc_points(cx, cy, radius, angle_start, angle_end, steps) = [
    for (point_index = [0 : steps])
        let(angle = angle_start
                    + (angle_end - angle_start) * point_index / steps)
            [cx + radius * cos(angle), cy + radius * sin(angle)]
];

// An 80%-width pull tab with convex fillets on its outer front corners and
// concave quarter-circle fillets where both sides blend into the lid plate.
// A single polygon avoids tangent-only Boolean joins in the final mesh.
module pull_tab_2d() {
    tab_x_min = body_center_x - lid_handle_width / 2;
    tab_x_max = body_center_x + lid_handle_width / 2;
    r = lid_handle_fillet_radius;
    root_y = 0;
    fillet_steps = max(4, ceil(curve_fn / 8));

    if (r <= 0) {
        translate([tab_x_min, -lid_handle_depth])
            square([
                lid_handle_width,
                lid_handle_depth + root_y + eps
            ]);
    } else {
        polygon(concat(
            [[tab_x_min - r, root_y + eps]],
            arc_points(
                tab_x_min - r, root_y - r, r,
                90, 0, fillet_steps
            ),
            [[tab_x_min, -lid_handle_depth + r]],
            arc_points(
                tab_x_min + r, -lid_handle_depth + r, r,
                180, 270, fillet_steps
            ),
            [[tab_x_max - r, -lid_handle_depth]],
            arc_points(
                tab_x_max - r, -lid_handle_depth + r, r,
                270, 360, fillet_steps
            ),
            [[tab_x_max, root_y - r]],
            arc_points(
                tab_x_max + r, root_y - r, r,
                180, 90, fillet_steps
            ),
            [[tab_x_max + r, root_y + eps]]
        ));
    }
}

module lid_plan_2d() {
    union() {
        lid_plate_2d();
        pull_tab_2d();

        // Carry the body-matching front stopper profile through the full lid
        // thickness. Behind this zone the base plate remains narrower so it
        // retains the clearance needed to slide through the side grooves.
        lid_front_stopper_2d();
    }
}

// Exact outside profile of the body's front edge, limited to the stopper
// depth shared by the lid and the corresponding body cutback.
module lid_front_stopper_2d() {
    intersection() {
        front_rounded_rect_2d(
            outer_width,
            outer_depth,
            front_edge_radius
        );
        square([outer_width, lid_fascia_depth]);
    }
}

// Raised lid surface. The front portion remains full-width to act as the
// insertion stopper. Behind it, the raised area is inset from the side and
// rear walls, leaving the base plate edges thin enough to enter the grooves.
module lid_flush_top_2d() {
    cap_side_inset = wall_thickness + lid_side_clearance;
    cap_rear_y = outer_depth - rear_wall_thickness - lid_rear_clearance;

    union() {
        // The same profile is used at both lid heights, keeping the front
        // corners vertically aligned and flush with the body walls.
        lid_front_stopper_2d();

        // Keep the pull tab at the same top level. Besides making it stronger,
        // this gives the inverted printable lid a continuous flat bed face.
        pull_tab_2d();

        // Central flush panel with clearance from both rails and the rear lip.
        intersection() {
            lid_plate_2d();
            translate([cap_side_inset, 0])
                square([
                    outer_width - 2 * cap_side_inset,
                    cap_rear_y
                ]);
        }
    }
}

// Remove 45-degree bevels from the upper edges that travel in the left, right,
// and rear grooves. The bevel width equals the groove depth, and its upper
// outline meets the raised central panel without an unsupported step.
module lid_edge_chamfer_cuts() {
    lid_x = body_center_x - lid_width / 2;
    sliding_y_min = lid_fascia_depth;
    sliding_y_span = lid_depth - sliding_y_min + eps;
    chamfer = lid_groove_depth;

    // Left edge.
    hull() {
        translate([
            lid_x - eps,
            sliding_y_min,
            lid_top_thickness - chamfer - eps
        ])
            cube([eps, sliding_y_span, eps]);

        translate([
            lid_x - eps,
            sliding_y_min,
            lid_top_thickness - eps
        ])
            cube([chamfer + 2 * eps, sliding_y_span, 2 * eps]);
    }

    // Right edge.
    hull() {
        translate([
            lid_x + lid_width,
            sliding_y_min,
            lid_top_thickness - chamfer - eps
        ])
            cube([eps, sliding_y_span, eps]);

        translate([
            lid_x + lid_width - chamfer - eps,
            sliding_y_min,
            lid_top_thickness - eps
        ])
            cube([chamfer + 2 * eps, sliding_y_span, 2 * eps]);
    }

    // Rear edge.
    hull() {
        translate([
            lid_x - eps,
            lid_depth,
            lid_top_thickness - chamfer - eps
        ])
            cube([lid_width + 2 * eps, eps, eps]);

        translate([
            lid_x - eps,
            lid_depth - chamfer - eps,
            lid_top_thickness - eps
        ])
            cube([lid_width + 2 * eps, chamfer + 2 * eps, 2 * eps]);
    }
}

module chamfered_lid_base() {
    difference() {
        linear_extrude(height = lid_top_thickness)
            lid_plan_2d();

        lid_edge_chamfer_cuts();
    }
}

// Shallow two-way ramp under the lid. In use it flexes over the top of the
// front wall, then rests over the open interior and resists accidental removal.
// Its small interference is controlled by lid_detent_height relative to half
// of lid_vertical_clearance.
module lid_retention_detent() {
    if (lid_detent_height > 0) {
        detent_x_min = body_center_x - lid_detent_length / 2;

        hull() {
            translate([
                detent_x_min,
                lid_detent_center_y - lid_detent_ramp_depth / 2,
                -eps
            ])
                cube([
                    lid_detent_length,
                    lid_detent_ramp_depth,
                    eps
                ]);

            translate([
                detent_x_min,
                lid_detent_center_y - eps / 2,
                -lid_detent_height
            ])
                cube([lid_detent_length, eps, eps]);
        }
    }
}

// Captured sliding lid. Its thin base plate runs in the body grooves; the
// raised central panel fills the space above it and finishes flush with the
// body's top face in the assembly preview.
module sliding_lid() {
    union() {
        chamfered_lid_base();
        lid_retention_detent();

        translate([0, 0, lid_top_thickness - eps])
            linear_extrude(height = lid_flush_top_height + eps)
                lid_flush_top_2d();
    }
}

// Print the lid top-face-down. Its broad raised panel and pull tab sit on the
// bed, the three chamfered sliding edges grow at 45 degrees, and the underside
// retention bump builds upward without support.
module printable_lid() {
    translate([outer_width, lid_handle_depth, lid_total_height])
        rotate([0, 180, 0])
            sliding_lid();
}

if (part_to_render == "body") {
    dispenser_body();
} else if (part_to_render == "lid") {
    printable_lid();
} else if (part_to_render == "print_layout") {
    dispenser_body();
    translate([outer_width + 10, 0, 0])
        printable_lid();
} else if (part_to_render == "assembly_preview") {
    color("goldenrod") dispenser_body();
    color("lightsteelblue", 0.8)
        translate([0, 0, lid_assembled_z])
            sliding_lid();
} else {
    assert(false,
           "part_to_render must be body, lid, print_layout, or assembly_preview.");
}
