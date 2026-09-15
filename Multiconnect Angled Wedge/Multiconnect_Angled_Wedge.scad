/*
Parametric Multiconnect angled wedge for Multiboard

The rear channels slide down over Flush Big Multiconnect connectors fixed to a
vertical Multiboard. The angled face reproduces the Multiboard big-thread socket
on a 25 mm grid, so additional Flush Big connectors can be screwed into it.

Interface references:
- Multiconnect connector drawing, 2024-01-10:
  https://makerworld.com/en/models/1026736
- Multiboard multihole dimensions checked against the community parametric tile:
  https://github.com/asciipip/multiboard-parametric-stacked

This is a non-trivial derivative intended for use under the applicable
Multiboard and Multiconnect license terms. Verify those terms before sharing or
selling derivatives.
*/

/* [Model] */
// Main part or a small interface test.
output_mode = "Wedge"; // [Wedge,Rear slot coupon,Front socket coupon]

/* [Size and angle] */
// Number of 25 mm Multiboard cells across the wedge.
units_wide = 2; // [1:1:8]
// Number of 25 mm Multiboard cells up the rear face.
units_high = 2; // [1:1:8]
// Angle between the vertical board and the angled front face.
tilt_from_vertical_deg = 30; // [15:5:60]
// Small flat depth remaining between rear and front faces at the top.
top_depth = 8; // [6:0.5:20]

/* [Rear Multiconnect channels] */
// Scales the complete receiver profile. 1.00 already includes about 0.15 mm
// clearance per side relative to the nominal 20/15 mm connector drawing.
rear_slot_scale = 1.00; // [0.97:0.005:1.05]
// Retaining ridge at the rounded top of each rear channel.
rear_locking_ridge = true;

/* [Front Multiboard sockets] */
// Added to both thread diameters; this is DIAMETRAL print clearance.
front_thread_diametral_clearance = 0.25; // [0:0.05:0.6]
// Show expensive thread geometry in F5 preview. F6 render always includes it.
preview_threads = false;

/* [Quality] */
round_facets = 64; // [32:8:128]
thread_facets_per_turn = 32; // [16:4:64]

/* [Hidden] */
pitch = 25;
epsilon = 0.02;

// Fixed structural thicknesses. These remain editable in source but are hidden
// from the Customizer because they are not normal end-user controls.
rear_skin = 6.5;
front_skin = 8;
// Fixed to suit the approximately 6.4 mm threaded shank of the connector.
front_socket_depth = 7;
bottom_skin = 3;
side_skin = 3;
internal_rib = 3;
top_skin = 3;

width = units_wide * pitch;
rear_height = units_high * pitch;
front_length = rear_height / cos(tilt_from_vertical_deg);
bottom_depth = top_depth + rear_height * tan(tilt_from_vertical_deg);
front_inset_y = front_skin / cos(tilt_from_vertical_deg);
cavity_peak_z = (bottom_depth - front_inset_y - rear_skin) /
                tan(tilt_from_vertical_deg);
cavity_top_z = min(rear_height - top_skin, cavity_peak_z);
rear_stop_z = rear_height - pitch / 2;
// A normal-depth socket also travels downward inside an inclined face. Move the
// front grid just enough uphill to keep the lowest thread fully inside the toe.
front_grid_structural_shift = front_socket_depth*tan(tilt_from_vertical_deg) + 0.5;

// Multiconnect receiver profile derived from the nominal 20/15 mm connector.
mc_outer_half = 10.15;
mc_neck_half = 7.65;
mc_outer_depth = 1.2121;
mc_taper_depth = 3.712;
mc_slot_depth = 5;

// Multiboard big multihole and thread dimensions.
mb_thick_flat = 21.4;
mb_thin_flat = 23.4;
mb_thread_major = 22.6;
mb_thread_minor = 21.4;
mb_thread_outer_height = 0.5;
mb_thread_inner_height = 1.583;
mb_thread_pitch = 2.5;
mb_entry_lip = 0.6;
mb_entry_taper = 1.4;

assert(units_wide >= 1 && units_wide == floor(units_wide),
       "units_wide must be a positive integer.");
assert(units_high >= 1 && units_high == floor(units_high),
       "units_high must be a positive integer.");
assert(tilt_from_vertical_deg >= 10 && tilt_from_vertical_deg <= 70,
       "Use a tilt between 10 and 70 degrees.");
assert(top_depth >= mc_slot_depth + 1,
       "Increase top_depth so the rear channel retains material at the top.");
assert(rear_skin >= mc_slot_depth + 0.8,
       "rear_skin must leave material behind the 5 mm Multiconnect channel.");
assert(front_skin >= front_socket_depth + 0.5,
       "front_skin must exceed front_socket_depth by at least 0.5 mm.");
assert(cavity_top_z > bottom_skin + 2,
       "The wedge is too small to hollow with these skins; reduce skins or increase size/depth.");
assert(side_skin * 2 < pitch && internal_rib < pitch,
       "Side skins and ribs must leave an open cavity bay.");
assert(front_thread_diametral_clearance >= 0 &&
       front_thread_diametral_clearance <= 0.8,
       "Use 0 to 0.8 mm diametral thread clearance.");

echo(width_mm=width,
     rear_height_mm=rear_height,
     bottom_depth_mm=bottom_depth,
     front_face_length_mm=front_length,
     tilt_from_vertical_deg=tilt_from_vertical_deg,
     front_socket_centres_from_bottom_mm=
        [for (row=[0:units_high-1])
            pitch/2 + front_grid_structural_shift + row*pitch]);

if (output_mode == "Wedge")
    angled_wedge();
else if (output_mode == "Rear slot coupon")
    rear_slot_coupon();
else if (output_mode == "Front socket coupon")
    front_socket_coupon();
else
    assert(false, "Choose a valid output_mode.");

module angled_wedge() {
    difference() {
        difference() {
            wedge_outer();
            wedge_cavities();
        }
        rear_channels();
        front_socket_grid();
    }
}

module wedge_outer() {
    prism_x(width, [
        [0, 0],
        [bottom_depth, 0],
        [top_depth, rear_height],
        [0, rear_height]
    ]);
}

// One cavity per 25 mm bay preserves transverse ribs at every cell boundary.
module wedge_cavities() {
    for (column=[0:units_wide-1]) {
        x0 = column == 0 ? side_skin : column*pitch + internal_rib/2;
        x1 = column == units_wide-1
             ? width-side_skin
             : (column+1)*pitch-internal_rib/2;
        y_front_at_bottom = bottom_depth
                            - bottom_skin*tan(tilt_from_vertical_deg)
                            - front_inset_y;

        translate([x0,0,0])
            prism_x(x1-x0, [
                [rear_skin, bottom_skin],
                [y_front_at_bottom, bottom_skin],
                [rear_skin, cavity_top_z]
            ]);
    }
}

module rear_channels() {
    for (column=[0:units_wide-1])
        translate([
            pitch/2 + column*pitch,
            mc_slot_depth*rear_slot_scale,
            0
        ])
            scale([rear_slot_scale,rear_slot_scale,rear_slot_scale])
                mirror([0,1,0])
                    rear_multiconnect_channel(rear_stop_z/rear_slot_scale);
}

// Continuous bottom-entry channel. Sliding the wedge downward seats all rear
// connectors; the uppermost connector meets the rounded stop and lock ridge.
module rear_multiconnect_channel(stop_z) {
    half_profile = [
        [0, -epsilon],
        [mc_outer_half, -epsilon],
        [mc_outer_half, mc_outer_depth],
        [mc_neck_half, mc_taper_depth],
        [mc_neck_half, mc_slot_depth + epsilon],
        [0, mc_slot_depth + epsilon]
    ];
    full_profile = concat(
        half_profile,
        [for (i=[len(half_profile)-2:-1:1])
            [-half_profile[i][0], half_profile[i][1]]]
    );

    difference() {
        union() {
            translate([0,0,-epsilon])
                linear_extrude(height=stop_z+epsilon)
                    polygon(full_profile);
            translate([0,0,stop_z])
                rotate([-90,0,0])
                    rotate_extrude($fn=round_facets)
                        polygon(half_profile);
        }
        if (rear_locking_ridge)
            translate([0,0,stop_z])
                rotate([-90,0,0])
                    rotate_extrude($fn=round_facets)
                        // Extends into the inner wall so the retained dimple
                        // is physically anchored rather than a floating cone.
                        polygon([[0,-0.25],[0,1.5],[1.5,-0.25]]);
    }
}

module front_socket_grid() {
    for (column=[0:units_wide-1])
        for (row=[0:units_high-1]) {
            along_face = pitch/2 + front_grid_structural_shift + row*pitch;
            x = pitch/2 + column*pitch;
            y = bottom_depth - along_face*sin(tilt_from_vertical_deg);
            z = along_face*cos(tilt_from_vertical_deg);

            translate([x,y,z])
                // Local +Z points normally inward from the angled face.
                rotate([90+tilt_from_vertical_deg,0,0])
                    translate([0,0,-epsilon])
                        multiboard_socket_cutter(front_socket_depth+epsilon);
        }
}

module multiboard_socket_cutter(depth) {
    clearance = front_thread_diametral_clearance;
    thin_d = (mb_thin_flat + clearance) / cos(22.5);
    thick_d = (mb_thick_flat + clearance) / cos(22.5);

    union() {
        rotate([0,0,22.5]) {
            cylinder(h=mb_entry_lip+epsilon, d=thin_d, $fn=8);
            translate([0,0,mb_entry_lip])
                cylinder(h=mb_entry_taper,
                         d1=thin_d, d2=thick_d, $fn=8);
            translate([0,0,mb_entry_lip+mb_entry_taper-epsilon])
                cylinder(h=depth-mb_entry_lip-mb_entry_taper+epsilon,
                         d=thick_d, $fn=8);
        }

        if (!$preview || preview_threads)
            intersection() {
                translate([0,0,-mb_thread_inner_height/2])
                    trapezoid_thread(
                        mb_thread_major + clearance,
                        mb_thread_minor + clearance,
                        mb_thread_outer_height,
                        mb_thread_inner_height,
                        depth + mb_thread_inner_height,
                        mb_thread_pitch,
                        thread_facets_per_turn
                    );
                translate([-15,-15,0]) cube([30,30,depth]);
            }
    }
}

module rear_slot_coupon() {
    coupon_w = 25;
    coupon_h = 35;
    coupon_d = rear_skin + 1.5;
    difference() {
        cube([coupon_w,coupon_d,coupon_h]);
        translate([
            coupon_w/2,
            mc_slot_depth*rear_slot_scale,
            0
        ])
            scale([rear_slot_scale,rear_slot_scale,rear_slot_scale])
                mirror([0,1,0])
                    rear_multiconnect_channel(
                        (coupon_h-12.5)/rear_slot_scale
                    );
    }
}

module front_socket_coupon() {
    coupon_size = 30;
    difference() {
        cube([coupon_size,coupon_size,front_skin]);
        translate([coupon_size/2,coupon_size/2,-epsilon])
            multiboard_socket_cutter(front_socket_depth+epsilon);
    }
}

// Extrudes a counter-clockwise [Y,Z] polygon along +X.
module prism_x(length, yz_points) {
    n = len(yz_points);
    vertices = concat(
        [for (p=yz_points) [0,p[0],p[1]]],
        [for (p=yz_points) [length,p[0],p[1]]]
    );
    faces = concat(
        [[for (i=[n-1:-1:0]) i]],
        [[for (i=[0:n-1]) n+i]],
        [for (i=[0:n-1])
            [i, (i+1)%n, n+(i+1)%n, n+i]]
    );
    polyhedron(points=vertices, faces=faces, convexity=10);
}

// Self-contained helical trapezoid used as an internal-thread cutter.
module trapezoid_thread(d_major, d_minor, h_outer, h_inner,
                        thread_length, thread_pitch, facets_per_turn) {
    profile = [
        [d_major/2, -h_outer/2],
        [d_major/2,  h_outer/2],
        [d_minor/2,  h_inner/2],
        [d_minor/2, -h_inner/2]
    ];
    segments = round(facets_per_turn*thread_length/thread_pitch);
    points = [
        for (segment=[0:segments])
            each thread_segment_points(
                profile,
                segment*360/facets_per_turn,
                segment*thread_pitch/facets_per_turn
            )
    ];
    faces = concat(
        [[3,2,1,0]],
        [for (segment=[0:segments-1])
            each thread_segment_faces(4,segment)],
        [[for (i=[0:3]) len(points)-4+i]]
    );
    polyhedron(points=points, faces=faces, convexity=12);
}

function thread_segment_points(profile, angle, z_offset) =
    [for (p=profile)
        [p[0]*cos(angle), p[0]*sin(angle), p[1]+z_offset]];

function thread_segment_faces(profile_count, segment) =
    [for (point=[0:profile_count-1])
        each let(
            a=segment*profile_count + (point+1)%profile_count,
            b=(segment+1)*profile_count + (point+1)%profile_count,
            c=(segment+1)*profile_count + point,
            d=segment*profile_count + point
        ) [[a,b,c],[a,c,d]]];
