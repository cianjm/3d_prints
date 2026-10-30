// ============================================================
//  Fit-over shield sunglasses - parametric prop model (OpenSCAD)
//  Sketched from a single product photo, so proportions are
//  estimates. Tweak the sliders, don't trust the defaults.
//
//  Axes: X = left/right, Y = front(-) to back(+), Z = up.
//  Units: mm.
//
//  One-piece shell: bowed front + straight side panels that
//  taper into ear tips, a notched lower edge for the nose,
//  a raised brow band along the top, and two screw bosses
//  with seam grooves where the front meets the sides.
//
//  PROP / DISPLAY ONLY. A printed shell gives no UV or impact
//  protection and is not optically clear enough to drive in.
// ============================================================

/* [Overall size] */
width         = 148;  // outer width across the front
height        = 50;   // top-to-bottom at the front
front_depth   = 36;   // how far the front bows forward of the sides
side_length   = 76;   // straight side panel length, front corner to ear tip
side_taper    = 5;    // how far each side angles inward by the ear tip
wall          = 1.8;  // shell thickness (1.6-2.0 prints well)
squareness    = 2.6;  // 2 = pure ellipse, higher = boxier front

/* [Lower edge] */
nose_width    = 20;   // width of the nose notch
nose_height   = 12;   // depth of the nose notch
cheek_lift    = 6;    // how much the lower edge rises toward the corners
temple_height = 16;   // side panel height at the ear tip
side_curve    = 1.6;  // >1 keeps sides tall longer, then swoops up

/* [Ear tips] */
tip_width     = 16;   // length of the downward tab at the rear
tip_drop      = 14;   // how far the tab hangs below the side panel

/* [Brow band] */
brow_height   = 5;    // height of the raised band along the top
brow_overhang = 1.6;  // how far it sticks out past the shell

/* [Vision openings] */
lens_mode     = "slots"; // [solid, slots, pinholes]
eye_spacing   = 64;   // pupil-to-pupil distance, measure yours (adults ~58-70)
eye_height    = 2;    // centre of the see-through zones above the shield's middle
eye_zone_w    = 32;   // width of each see-through zone
eye_zone_h    = 22;   // height of each see-through zone
slot_height   = 1.4;  // slots: height of each slit
slot_pitch    = 3.6;  // slots: centre-to-centre spacing between slits
hole_diameter = 1.6;  // pinholes: diameter
hole_pitch    = 3.6;  // pinholes: centre-to-centre spacing

/* [Screw bosses and seams] */
boss_on       = true;
boss_diameter = 5;
boss_height   = 1.6;  // raised above the top (ignored when for_print)
screw_hole    = 2;
boss_angle    = 28;   // degrees along the front curve, measured from the side
seam_groove   = true;
groove_depth  = 0.5;
groove_width  = 0.7;

/* [Output] */
for_print     = false; // true = flip so the top edge sits flat on the bed

/* [Hidden] */
$fn = 48;
boss_h_eff = for_print ? 0 : boss_height;

// ---------- helpers ----------
function sgn(v) = v < 0 ? -1 : 1;

// Superellipse front curve, t = 0 (right side) .. 180 (left side)
function se_x(t) = (width / 2) * sgn(cos(t)) * pow(abs(cos(t)), 2 / squareness);
function se_y(t) = -front_depth * pow(abs(sin(t)), 2 / squareness);
function bp(t)   = [se_x(t), se_y(t)];

function tang(t) = bp(t + 0.5) - bp(t - 0.5);
function outn(t) = let(T = tang(t), n = norm(T)) [-T[1] / n, T[0] / n];

// Lower edge seen from the front (nose notch + cheek rise)
function lower_z(x) =
    -height / 2
    + cheek_lift * pow(abs(x) / (width / 2), 3)
    + nose_height * max(0, 1 - pow(abs(x) / (nose_width / 2), 2));

// Lower edge seen from the side (swoop up, then ear-tip tab)
tab_start = side_length - tip_width;
function side_z(y) =
    y <= 0 ? -height / 2 - 5 :
    y < tab_start
        ? -height / 2 + (height - temple_height) * pow(y / tab_start, side_curve)
        : height / 2 - temple_height
          - tip_drop * pow(max(0, sin(180 * pow((y - tab_start) / tip_width, 1.5))), 0.6);

// ---------- 2D plan outline ----------
module plan_filled() {
    Le = side_length + 2 * wall + 6;           // extended, trimmed later
    ta = side_taper * Le / side_length;
    polygon(concat(
        [for (t = [0 : 3 : 180]) bp(t)],
        [[-(width / 2 - ta), Le], [(width / 2 - ta), Le]]
    ));
}

module plan_ring(outer_extra = 0) {
    difference() {
        offset(delta = outer_extra) plan_filled();
        offset(delta = -wall) plan_filled();
    }
}

module trim_back() {
    translate([-width, side_length, -height * 2])
        cube([2 * width, 100, height * 4]);
}

// ---------- trimming profiles ----------
module lower_profile_xz() {
    n  = 60;
    x0 = -width / 2 - 2;
    dx = (width + 4) / n;
    rotate([90, 0, 0]) linear_extrude(height = 400, center = true)
        polygon(concat(
            [[x0, height / 2 + 5]],
            [for (i = [0 : n]) [x0 + i * dx, lower_z(x0 + i * dx)]],
            [[width / 2 + 2, height / 2 + 5]]
        ));
}

// lower_profile_xz() shapes the nose/cheek curve but is extruded the
// full length of Y; left unguarded it also clips the side panels
// wherever the cheek curve sits above side_z(y). The two curves cross
// partway along the side at a slope mismatch (kink), pinching the
// wall to a sub-nozzle sliver right at the front/side corner. Clamp
// the cheek cut to y <= guard (the front only) and leave y > -guard
// fully open so side_profile_yz alone governs the side panels, with
// a hairline overlap for a watertight seam.
module lower_profile_region() {
    guard = 0.01;
    big = 2000;
    union() {
        intersection() {
            lower_profile_xz();
            translate([-big / 2, -big, -big / 2]) cube([big, big + guard, big]);
        }
        translate([-big / 2, -guard, -big / 2]) cube([big, big, big]);
    }
}

module side_profile_yz() {
    n = 60;
    rotate([90, 0, 90]) linear_extrude(height = 400, center = true)
        polygon(concat(
            [[-front_depth - 10, height / 2 + 5],
             [side_length + 5,   height / 2 + 5],
             [side_length + 5,   side_z(side_length)]],
            [for (i = [0 : n]) let(y = side_length * (n - i) / n) [y, side_z(y)]],
            [[-front_depth - 10, -height / 2 - 5]]
        ));
}

// ---------- parts ----------
module shell_body() {
    intersection() {
        difference() {
            translate([0, 0, -height / 2])
                linear_extrude(height = height) plan_ring(0);
            trim_back();
        }
        lower_profile_region();
        side_profile_yz();
    }
}

module brow() {
    intersection() {
        difference() {
            translate([0, 0, height / 2 - brow_height])
                linear_extrude(height = brow_height) plan_ring(brow_overhang);
            trim_back();
        }
        side_profile_yz();
    }
}

function boss_mid(t) = bp(t) + outn(t) * (brow_overhang - wall) / 2;

module boss_pad() {
    m = boss_mid(boss_angle);
    translate([m[0], m[1], height / 2 - 1])
        cylinder(d = boss_diameter, h = 1 + boss_h_eff);
}

module boss_hole() {
    m = boss_mid(boss_angle);
    translate([m[0], m[1], height / 2 - 3.5])
        cylinder(d = screw_hole, h = 10);
}

module seam_cut() {
    p = bp(boss_angle);
    n = outn(boss_angle);
    zbot = -height / 2 - 1;
    ztop = height / 2 - brow_height;
    translate([p[0], p[1], (zbot + ztop) / 2])
        rotate([0, 0, atan2(n[1], n[0])])
            cube([2 * groove_depth, groove_width, ztop - zbot], center = true);
}

// ---------- see-through openings ----------
assert(eye_height + eye_zone_h / 2 < height / 2 - brow_height,
       "Eye zone runs into the brow band: lower eye_height or shrink eye_zone_h");

// One eye's pattern, drawn in the X/Z plane around (0,0)
module eye_pattern_2d() {
    if (lens_mode == "slots") {
        rows = max(1, floor(eye_zone_h / slot_pitch));
        for (i = [0 : rows - 1])
            translate([0, (i - (rows - 1) / 2) * slot_pitch])
                hull() {
                    translate([-(eye_zone_w - slot_height) / 2, 0]) circle(d = slot_height, $fn = 16);
                    translate([ (eye_zone_w - slot_height) / 2, 0]) circle(d = slot_height, $fn = 16);
                }
    } else if (lens_mode == "pinholes") {
        row_h = hole_pitch * 0.866;                       // hex grid
        nc = ceil(eye_zone_w / 2 / hole_pitch) + 1;
        nr = ceil(eye_zone_h / 2 / row_h) + 1;
        for (r = [-nr : nr], c = [-nc : nc]) {
            x = (c + (abs(r) % 2 == 0 ? 0 : 0.5)) * hole_pitch;
            y = r * row_h;
            if (pow(x / (eye_zone_w / 2), 2) + pow(y / (eye_zone_h / 2), 2) <= 1)
                translate([x, y]) circle(d = hole_diameter, $fn = 12);
        }
    }
}

// Cuts straight through the front wall along Y, one zone per eye
module vision_cut() {
    if (lens_mode != "solid")
        for (s = [-1, 1])
            translate([s * eye_spacing / 2, -10, eye_height])
                rotate([90, 0, 0])
                    linear_extrude(height = front_depth - 5) eye_pattern_2d();
}

module both_sides() {
    children();
    mirror([1, 0, 0]) children();
}

module sunglasses() {
    difference() {
        union() {
            shell_body();
            brow();
            if (boss_on && boss_h_eff > 0) both_sides() boss_pad();
        }
        vision_cut();
        if (boss_on)     both_sides() boss_hole();
        if (seam_groove) both_sides() seam_cut();
    }
}

// ---------- output ----------
color([0.18, 0.18, 0.2])
if (for_print)
    translate([0, 0, height / 2]) rotate([180, 0, 0]) sunglasses();
else
    sunglasses();
