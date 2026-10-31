# -*- coding: utf-8 -*-
"""
Wise Coverup fit-over shield sunglasses -- parametric 3D-print prop generator (Blender 5.x)
==========================================================================================
This file is the single source of truth for all generated geometry.  Run it inside Blender:

    exec(open(r"C:\\repos\\3d_prints\\sunglasses\\coverup_shades_blender.py").read(), {})

Optional globals (pass them in the dict given to exec):
    COVERUP_STAGE   'a'..'h'  build only up to a stage (default 'h' = everything)
                    a lens base surface      b brow deck + crisp edge   c nose notch / bottom edge
                    d side panel edge curves e hinge caps + seams        f vision pinholes
                    g arms + inlay channel   h lap-joint alignment pin holes
    COVERUP_EXPORT  write the three STLs and save the .blend (default True for stage 'h')
    COVERUP_RENDER  render the matched-angle review images (default False)
    COVERUP_OVERRIDES  dict of parameter overrides, e.g. {"FRONT_SAG": 28.0} (for experiments)

Assembly frame: millimetres, +Z up, -Y forward (Blender's Front view looks at the lens front),
X across the face.  Brow top at Z_TOP, lowest lens point at Z_TOP - LENS_HEIGHT.

Construction
------------
The shell is generated from a smooth parametric surface S(w, z): w runs around the lens
(front -> front-to-side turn -> side panel, mirrored for the left), z is world height.  Every
horizontal section is a convex plan curve: y = y0 + A*|x/Xc|^p across the front, a CORNER_R
arc for the turn, then a straight side panel.  The lens outline (notch, bottom edge, side
panel curves) and the vision pinholes are polygons in the (w, z) domain; the domain is
triangulated (constrained Delaunay) and mapped to an outer surface and an inner surface
offset by WALL along the normal, then stitched along the boundary.  That gives one closed
manifold sheet by construction, with every hole running along the surface normal.
The brow deck, top/bottom trims, the arm inlay (joggle + channel), hinge caps, seam
grooves and screw/pin holes are applied with Blender's Manifold boolean solver.

Arm joint (inlay): over the arm band the side panel is joggled inward by the arm thickness
(a JOGGLE_WALL wall sitting ARM_INLAY_T + ARM_LAP_GAP inside the panel's outer surface), forming an
open channel.  The arm is a flat band whose outer face lies on the best-fit plane of the
panel surface over that band, so it sits flush; only hairline seams show (its lower edge,
and its front end against the hinge cap on the seam line).  Two filament pins register it.

Top line: the brow deck's top slopes down from its rear edge to the crisp brow edge at Z_TOP
(DECK_RISE, its own swept cutter).  Behind the hinge caps the side / arm top line starts
HINGE_JOIN_H higher, level with the cap's rear top and with the same outer chamfer, and falls
smoothly back onto the 6-deg base line over TOP_BUMP_LEN; the arm band below it is unchanged.

Everything generated lives in the "CoverupShades_Gen" collection and is deleted and rebuilt
on every run; reference image empties live in "CoverupShades_Refs" and are realigned.
"""

import bpy, bmesh, math, os, struct
import numpy as np
from mathutils import Vector, Matrix
from mathutils import geometry as mgeo
from mathutils.kdtree import KDTree

# =====================================================================================
# PARAMETERS (mm / degrees)
# =====================================================================================
# ---- overall ----
OVERALL_WIDTH     = 151.0   # outer width across the side panels at brow level (head clearance)
LENS_HEIGHT       = 50.0    # brow top to the lowest point of the lens bottom edge
Z_TOP             = 25.0    # world z of the brow top in the assembly frame
WALL              = 2.1     # shell wall thickness, measured along the surface normal

# ---- front face, plan view ----
FRONT_SAG         = 28.0    # at brow level the centre is this far forward of the turn end
                            # (28 fits the side + 3/4 photos better than 19; see report)
FRONT_POWER       = 2.5     # front plan curve y ~ |x|^p (>= 2: convex, flatter in the middle)
CORNER_R          = 8.0     # outer radius of the front-to-side turn

# ---- rake, side view ----
RAKE_CENTER       = 14.0    # face centre at the bottom sits this far behind the brow front
RAKE_SIDE         = 8.0     # same for the turn / seam line (the sides lean back less)
RAKE_LINEAR       = 0.45    # 1 = straight face in profile; < 1 = convex (curves back lower down)
BOTTOM_TUCK_R     = 6.0     # side-view rounding radius where the face meets the bottom edge
BOTTOM_TUCK_END   = 45.0    # deg from vertical the face reaches at the bottom edge (45 keeps
                            # the upright print free of overhang there)

# ---- front-view taper ----
SIDE_TAPER        = 14.0    # side panels pull inward by this much at the lens bottom (per side)
SIDE_TAPER_V1     = 0.45    # straight (planar) above this relative depth v: covers the whole arm
                            # band, so the flat arm inlays flush ...
SIDE_TAPER_K1     = 3.3     # ... with this gentle lean (mm per unit v) for head clearance,
SIDE_TAPER_V2     = 0.58    # then a smooth shoulder down to v2 and a straight pull-in to the
                            # bottom corner: about 0.8/1.9/3.9/10.4/12.5 mm at 12/25/30/43/47 mm

# ---- brow deck ----
DECK_T            = 3.5     # deck thickness (measured under its sloped top)
DECK_DEPTH_C      = 12.5    # deck depth front-to-back at the centre
DECK_DEPTH_TURN   = 10.0    # where the front curve meets the turn (the inner edge rounds the
                            # corner on a Hermite curve, so it is not limited by CORNER_R)
DECK_CORNER_IN    = 5.0     # inner-edge rounding starts this far (w) before the turn ...
DECK_CORNER_OUT   = 1.0     # ... and ends this far behind it
DECK_CORNER_K     = 0.8     # Hermite tangent length / chord (fullness of the rounded corner)
DECK_DEPTH_SEAM   = 9.3     # just behind the turn, under the rear of the hinge cap (a little
                            # less than HINGE_WID, so the cap covers the deck where the top steps up)
DECK_RISE         = 3.4     # the deck top rises from the crisp brow edge toward the face:
                            # its rear edge sits this much higher (about 15 deg at the centre), so
                            # in the front view the brow's top line is level with the cap tops
DECK_RISE_FADE    = (-2.0, -8.0)  # ... fading out between these distances (w) ahead of the cap
                            # front (negative: inside it): the deck runs on raised into the cap's
                            # narrow front (no notch beside it) and is level beside its rear,
                            # where the cap's inner face stands about 3 mm
DECK_RISE_EASE    = 0.35    # fraction of the rise eased off toward the corners before that fade
DECK_DEPTH_SIDE   = 5.55    # along the side (arm channel + joggled wall + lip; >= 139 mm inside)
DECK_DEPTH_REAR   = 3.6     # at the rear end (lip tapers out)
DECK_SIDE_SLOPE   = 6.0     # deg, the deck / panel top slopes down toward the rear from the seam
DECK_SLOPE_BLEND  = 10.0    # length of the smooth flat-to-slope transition
DECK_REAR_INSET   = 0.25    # deck stops this far short of the panel rear end
TOP_MARGIN        = 1.5     # shell + deck are built this much taller, then trimmed flat
BROW_FACET_H      = 0.0     # optional 45-deg facet between brow face and deck top (0 = off)

# ---- nose notch (front view) ----
NOTCH_HEIGHT      = 17.0    # rise from the bottom edge to the apex
NOTCH_APEX_R      = 5.5     # apex radius (apex ~11 mm wide)
NOTCH_SIDE_ANG    = 40.0    # deg from vertical of the straight notch sides
NOTCH_FLARE_R     = 18.0    # concave flare radius into the bottom edge

# ---- bottom edge ----
BOTTOM_FLAT_X     = 44.0    # front bottom edge is flat out to |x| = this
BOTTOM_RISE_TURN0 = 1.0     # rise of the bottom edge where the turn starts
BOTTOM_RISE_TURN1 = 2.0     # rise at the end of the turn = side panel bottom level at the front
                            # (small, so in the side view the bottom outline runs on in one arc
                            # instead of dipping at the turn and stepping up behind it)

# ---- side panels ----
PANEL_LENGTH      = 88.0    # from the brow-level turn end back to the panel (joggle) rear end
SIDE_FLAT         = 10.0    # flat run of the side bottom edge before the S-curve starts
PANEL_MERGE_BACK  = 2.0     # the S-curve meets the arm's lower edge this far before the rear end
PANEL_MERGE_GAP   = 0.3     # visible panel strip left under the arm edge at the merge point

# ---- seam groove ----
SEAM_OFFSET       = 1.5     # seam centre line behind the end of the turn
SEAM_DEPTH        = 0.5
SEAM_WIDTH        = 0.6
SEAM_END_GAP      = 0.6     # the groove stops this far above the bottom edge (no notch in the
SEAM_END_TAPER    = 2.0     # outline) and fades in over this length

# ---- hinge caps (corner pieces) ----
HINGE_LEN         = 10.0    # along the outer edge, forward from the seam (wraps the turn)
HINGE_WID         = 9.5     # inward from the outer surface at the cap's rear (seam) end
HINGE_INNER_LEN   = 4.0     # straight inner edge (parallel to the side) before the diagonal
HINGE_FRONT_W     = 1.0     # width of the cap's small front face
HINGE_JOIN_H      = 2.5     # arm top (and panel top) at the joint, above the brow edge: the cap's
                            # rear runs level into it and the top line then falls away rearward
HINGE_H_REAR      = HINGE_JOIN_H + 0.05   # cap top at the rear (0.05 proud: no coplanar faces)
HINGE_H_FRONT     = 1.0     # cap top at the front end, rising (along the cap, fractions from its
HINGE_H_PEAK      = 3.0     # front) to this peak round the screw hole: a 3 mm inner face over the
HINGE_PEAK_FROM   = 0.18    # deck (a steep sloped front face: most of the rise by here, the last
HINGE_PEAK_CLIMB  = 0.18    # it climbed gently past the hole up to HINGE_PEAK_TO) ...
HINGE_PEAK_TO     = 0.75    # ... then rounding down to HINGE_H_REAR at the rear face, with zero
                            # slope there, so it runs tangentially into the arm's top edge
HINGE_CHAMFER     = 2.5     # 45-deg chamfer on the outer top edge at the front (rounds the corner)
HINGE_CHAMFER_REAR = 1.4    # ... narrowing to this at the rear = the arm's top-edge chamfer
TOP_BUMP_LEN      = 57.0    # the raised top line at the joint falls back onto the 6-deg line over this
HINGE_DROP        = 9.0     # the cap's outer face runs this far down the corner (outlined)
HINGE_EMBED       = 1.0     # how far the raised part is sunk into the deck
HINGE_SEAM_GAP    = 0.1     # cap rear face sits this far in front of the channel front wall
HINGE_HOLE_D      = 3.0
HINGE_HOLE_DEPTH  = 2.5
HINGE_HOLE_BACK   = 4.0     # hole centre this far in front of the cap rear face (on the peak)
CAP_GROOVE_W      = 0.5     # outline groove of the cap on the corner surface
CAP_GROOVE_D      = 0.4

# ---- vision pinholes ----
PIN_D             = 1.6
PIN_PITCH         = 3.6     # hex grid pitch
PIN_ZONE_W        = 32.0    # elliptical zone per eye
PIN_ZONE_H        = 22.0
EYE_X             = 32.0    # eye centres at +-EYE_X
EYE_Z             = 3.0     # above the lens vertical middle (z = Z_TOP - LENS_HEIGHT/2)
EYE_DEPTH         = 30.0    # world y of the wearer's eye: each pinhole is drilled along the
                            # line from the eye through it (open along every line of sight)
PIN_SEGS          = 16
PIN_EDGE_MARGIN   = 3.0

# ---- arms ----
ARM_T             = 3.0     # plate thickness behind the panel
ARM_INLAY_T       = 2.0     # plate thickness inside the channel (keeps head clearance; the step is
                            # on the hidden inner face, at the panel rear end, so it prints flat)
ARM_H0            = 13.0    # height over the inlay (constant to the panel rear end; the front end is
                            # HINGE_JOIN_H taller where the top line rises into the hinge cap)
ARM_TOP_CHAMFER   = HINGE_CHAMFER_REAR   # 45-deg chamfer on the arm's outer top edge at the joint
ARM_CHAMFER_LEN   = 25.0    # ... fading out over this length (on the bed side: prints flat)
ARM_H1            = 9.0     # height from the end of the taper to the tip
ARM_LENGTH        = 145.0   # hinge screw to tip, along the centre line (user's own pair)
ARM_TAPER_LEN     = 65.0    # H0 -> H1 taper length from the panel rear end: ends near the tip, so the
                            # arm stays ~11 mm tall through the knee (photo) and the lower edge level
ARM_BEND_RUN      = 32.0    # bend start -> tip extremity, horizontal, measured on the centre line
ARM_BEND_DROP     = 25.0    # bend start -> tip extremity, vertical drop of the centre line
ARM_BEND_POWER    = 0.25    # curvature ramps up as u^p along the bend: >0 concentrates it at the end
ARM_LAP_GAP       = 0.15    # glue gap between the channel floor and the arm's inner face
ARM_EDGE_GAP      = 0.15    # clearance between the arm's lower edge and the channel step
JOGGLE_WALL       = 1.3     # wall the panel is joggled onto behind the arm
JOGGLE_TAPER      = 0.81    # it thins to this fraction at its rear end (>= 1.05 mm)
ARM_STEP_GAP      = 0.3     # arm's thick part starts this far behind the joggle rear end

# ---- lap joint pins ----
JOINT_PIN_D       = 2.0     # holes for 1.75 mm filament pins
JOINT_PIN_SEGS    = 20
JOINT_PIN_FRONT   = 9.0     # first pin this far behind the arm front end
JOINT_PIN_REAR    = 14.0    # second pin this far in front of the panel rear end

# ---- meshing / output ----
MESH_STEP         = 1.0     # domain triangle size for the shell
OUT_DIR           = r"C:\repos\3d_prints\sunglasses"
RENDER_DIR        = r"C:\Users\cianj\AppData\Local\Temp\claude\C--repos-3d-prints\0243dc96-f90a-41af-b59d-b825be82afeb\scratchpad"
GEN_COLL          = "CoverupShades_Gen"
REF_COLL          = "CoverupShades_Refs"

_G = globals()
STAGE  = str(_G.get("COVERUP_STAGE", "h")).lower()
EXPORT = bool(_G.get("COVERUP_EXPORT", STAGE == "h"))
RENDER = bool(_G.get("COVERUP_RENDER", False))
for _k, _v in dict(_G.get("COVERUP_OVERRIDES", {}) or {}).items():
    _G[_k] = _v


def has(stage):
    return STAGE >= stage


# =====================================================================================
# PARAMETRIC SURFACE
# =====================================================================================
W_TOP = OVERALL_WIDTH / 2.0
Z_BOT = Z_TOP - LENS_HEIGHT
Z_MID = Z_TOP - LENS_HEIGHT / 2.0
TAN_DS = math.tan(math.radians(DECK_SIDE_SLOPE)) if has('b') else 0.0
TOPM = TOP_MARGIN if has('b') else 0.0


def _inset(v):
    """Front-view pull-in of the side panels (per side) at relative depth v: straight
    (planar panel, so the flat arm inlays flush) down to SIDE_TAPER_V1, then curving in
    progressively (C1) to SIDE_TAPER at the bottom."""
    v = np.asarray(v, float)
    v1, v2, k1, T = SIDE_TAPER_V1, SIDE_TAPER_V2, SIDE_TAPER_K1, SIDE_TAPER
    s2 = (T - k1 * v2 + k1 * (v2 - v1) / 2) / ((v2 - v1) / 2 + (1 - v2))   # slope below v2
    q = (s2 - k1) / (2 * (v2 - v1))
    i2 = k1 * v2 + q * (v2 - v1) ** 2
    return np.where(v <= v1, k1 * v,
                    np.where(v <= v2, k1 * v + q * (v - v1) ** 2, i2 + s2 * (v - v2)))


def _tuck(z):
    """Extra pull-back of the face centre near the bottom: the side profile rounds into the
    bottom edge on a BOTTOM_TUCK_R arc (from the rake angle to BOTTOM_TUCK_END from
    vertical) instead of meeting it in a sharp 'chin'.  C1 with the plain rake above."""
    z = np.asarray(z, float)
    r = BOTTOM_TUCK_R
    if r <= 0:
        return np.zeros_like(z)
    s0 = RAKE_CENTER * (RAKE_LINEAR + 2 * (1 - RAKE_LINEAR)) / LENS_HEIGHT
    t0 = math.atan(s0); t1 = math.radians(BOTTOM_TUCK_END)
    h = r * (math.cos(t0) - math.cos(t1))               # height of the rounded zone
    d = z - Z_BOT
    dd = np.clip(d, 0.0, h)
    th = np.arccos(np.clip(math.cos(t0) - (h - dd) / r, -1, 1))
    tk = r * (np.sin(th) - math.sin(t0)) - s0 * (h - dd)
    tk0 = r * (math.sin(t1) - math.sin(t0)) - s0 * h
    below = tk0 + (math.tan(t1) - s0) * np.maximum(0.0, -d)   # straight continuation below
    return np.where(d >= h, 0.0, np.where(d >= 0, tk, below))


def _sec(z):
    """Horizontal section parameters at height(s) z."""
    z = np.atleast_1d(np.asarray(z, dtype=float))
    v = (Z_TOP - z) / LENS_HEIGHT                       # 0 at brow, 1 at bottom
    prof = RAKE_LINEAR * v + (1.0 - RAKE_LINEAR) * v * v
    y0 = RAKE_CENTER * prof + _tuck(z)                  # centre front
    rs = RAKE_SIDE * prof                               # turn end (side panels)
    W = W_TOP - _inset(v)                               # side panel outer surface
    sag = FRONT_SAG + rs - y0
    R = CORNER_R
    phi = np.full_like(z, 0.3)
    for _ in range(80):                                 # solve the tangent turn-start angle
        Xc = W - R * (1.0 - np.sin(phi))
        A = sag - R * np.cos(phi)
        phi = np.arctan(A * FRONT_POWER / Xc)
    Xc = W - R * (1.0 - np.sin(phi))
    A = sag - R * np.cos(phi)
    return dict(v=v, y0=y0, rs=rs, W=W, sag=sag, phi=phi, Xc=Xc, A=A)


_s0 = _sec(Z_TOP)
XC_REF = float(_s0['Xc'][0])
PHI_REF = float(_s0['phi'][0])
LC_REF = CORNER_R * (math.pi / 2 - PHI_REF)
WC0 = XC_REF + LC_REF                                   # domain w where the side panel starts
W_SEAM = WC0 + SEAM_OFFSET                              # domain w of the seam centre line


def surf_P(w, z):
    """Outer surface point for domain coords (w, z); w < 0 is the mirrored (left) half."""
    w, z = np.broadcast_arrays(np.asarray(w, float), np.asarray(z, float))
    shp = w.shape
    w = w.ravel(); z = z.ravel()
    s = _sec(z)
    aw = np.abs(w)
    R = CORNER_R
    t = np.minimum(aw / XC_REF, 1.0)
    xf = (aw / XC_REF) * s['Xc']
    yf = s['y0'] + s['A'] * np.power(t, FRONT_POWER)
    frac = np.clip((aw - XC_REF) / LC_REF, 0.0, 1.0)
    ph = s['phi'] + frac * (np.pi / 2 - s['phi'])
    cx = s['Xc'] - R * np.sin(s['phi'])
    cy = s['y0'] + s['A'] + R * np.cos(s['phi'])
    xt = cx + R * np.sin(ph)
    yt = cy - R * np.cos(ph)
    xs = s['W']
    ys = FRONT_SAG + s['rs'] + (aw - WC0)
    x = np.where(aw <= XC_REF, xf, np.where(aw <= WC0, xt, xs))
    y = np.where(aw <= XC_REF, yf, np.where(aw <= WC0, yt, ys))
    x = np.where(w < 0, -x, x)
    return np.stack([x, y, z], axis=-1).reshape(shp + (3,))


def surf_PN(w, z, h=1e-3):
    """Point, outward unit normal and partial derivatives."""
    w = np.asarray(w, float); z = np.asarray(z, float)
    P = surf_P(w, z)
    Pw = (surf_P(w + h, z) - surf_P(w - h, z)) / (2 * h)
    Pz = (surf_P(w, z + h) - surf_P(w, z - h)) / (2 * h)
    N = np.cross(Pw, Pz)
    N = N / np.linalg.norm(N, axis=-1, keepdims=True)
    return P, N, Pw, Pz


def w_from_front(x, z):
    """Domain w for a front-view position (x >= 0, z) on the front or the turn."""
    x = np.atleast_1d(np.asarray(x, float)); z = np.atleast_1d(np.asarray(z, float))
    s = _sec(z)
    cx = s['Xc'] - CORNER_R * np.sin(s['phi'])
    wf = x * XC_REF / s['Xc']
    ph = np.arcsin(np.clip((x - cx) / CORNER_R, -1, 1))
    wt = XC_REF + (ph - s['phi']) / (np.pi / 2 - s['phi']) * LC_REF
    return np.where(x <= s['Xc'], wf, wt)


def y_corner(z):
    return FRONT_SAG + _sec(z)['rs']


def w_from_side(y, z):
    """Domain w for a side-view position (y, z) on the side panel."""
    return WC0 + (np.asarray(y, float) - y_corner(z))


def x_side(z):
    """x of the side panel outer surface (right side) at height z."""
    return W_TOP - _inset((Z_TOP - np.asarray(z, float)) / LENS_HEIGHT)


# The bottom edge faces run along the (raked) surface normal, so they are tilted.  The
# front bottom edge is designed this much lower and trimmed flat at Z_BOT, which gives the
# upright print a flat strip on the bed.
_Pb, _Nb, _, _ = surf_PN(np.array([35.0]), np.array([Z_BOT]))
BOTTOM_TRIM = WALL * abs(float(_Nb[0, 2])) + 0.05

Y_SEAM_TOP = FRONT_SAG + SEAM_OFFSET                     # seam centre at brow level
Y_SLOPE0 = Y_SEAM_TOP                                    # deck starts sloping at the seam
Y_REAR = FRONT_SAG + PANEL_LENGTH                        # rear end of the panel / joggle
Y_MERGE = Y_REAR - PANEL_MERGE_BACK                      # S-curve meets the arm's lower edge


Y_CAP_REAR = FRONT_SAG + SEAM_OFFSET - SEAM_WIDTH / 2 + 0.05 - HINGE_SEAM_GAP   # cap rear face
Y_JOIN = Y_CAP_REAR - 0.25        # the raised side top line starts here (hidden under the cap)
JOIN_H = HINGE_JOIN_H if has('e') else 0.0


def z_baseline(y):
    """Base top line (world y): flat at Z_TOP to the seam, then a smooth 6-deg fall.  The arm
    band (lower edge, channel step, pins) hangs from this line at constant height."""
    y = np.asarray(y, float)
    d = y - Y_SLOPE0
    L = DECK_SLOPE_BLEND
    return np.where(d <= 0, Z_TOP,
                    np.where(d <= L, Z_TOP - TAN_DS * d * d / (2 * L),
                             Z_TOP - TAN_DS * (d - L / 2)))


def dz_baseline(y):
    y = np.asarray(y, float)
    d = y - Y_SLOPE0
    L = DECK_SLOPE_BLEND
    return np.where(d <= 0, 0.0, np.where(d <= L, -TAN_DS * d / L, -TAN_DS))


def top_bump(y):
    """Extra height of the side top line behind the hinge cap: JOIN_H at the joint (level,
    so the cap top runs straight into the arm top) falling smoothly back to 0."""
    y = np.asarray(y, float)
    t = np.clip((y - Y_JOIN) / TOP_BUMP_LEN, 0.0, 1.0)
    return np.where(y < Y_JOIN - 0.05, 0.0, JOIN_H * (1.0 - t * t * (3 - 2 * t)))


def z_topline(y):
    """Panel / lip / arm top height behind the brow (world y).  In front of Y_JOIN the brow
    deck is shaped by its own sloped cutter; this line is only the side and arm top there."""
    return z_baseline(y) + top_bump(y)


def z_topline_build(y):
    """Height the shell / deck / joggle are built up to (then trimmed): covers the step
    at Y_JOIN from both sides."""
    y = np.asarray(y, float)
    return np.maximum(z_topline(y), z_topline(y + 0.6))


def y_seam(z):
    return y_corner(z) + SEAM_OFFSET


def y_channel_front(z):
    """Front wall of the arm channel (just behind the seam groove's front edge)."""
    return y_seam(z) - SEAM_WIDTH / 2 + 0.05


def y_arm_front(z):
    """Arm front end: the seam groove's rear edge (the seam reads as one line)."""
    return y_seam(z) + SEAM_WIDTH / 2


def arm_bottom_z(y):
    """World z of the arm's lower edge over the inlay (ARM_H0 below the base top line)."""
    ang = np.arctan(-dz_baseline(y))
    return z_baseline(y) - ARM_H0 / np.cos(ang)


def band_bottom(y):
    """Channel step: just below the arm's lower edge."""
    return arm_bottom_z(y) - ARM_EDGE_GAP


def d_band_bottom(y, h=1e-3):
    return (band_bottom(np.asarray(y, float) + h) - band_bottom(np.asarray(y, float) - h)) / (2 * h)


def _fit_arm_plane():
    """Best-fit plane x = a + b*y + c*z of the side panel surface along the arm band's
    top and lower edges: the arm's outer face, so the inlaid arm sits flush."""
    ys = np.linspace(Y_SEAM_TOP, Y_REAR, 80)
    Z = np.concatenate([z_topline(ys), arm_bottom_z(ys)])
    Y = np.concatenate([ys, ys])
    X = x_side(Z)
    A = np.stack([np.ones_like(Y), Y, Z], 1)
    coef, *_ = np.linalg.lstsq(A, X, rcond=None)
    dev = X - A @ coef
    return coef, float(np.abs(dev).max())


(PLANE_A, PLANE_B, PLANE_C), PLANE_DEV = _fit_arm_plane()
PANEL_N = np.array([1.0, -PLANE_B, -PLANE_C])
PANEL_N = PANEL_N / np.linalg.norm(PANEL_N)              # right arm plane outward normal


def plane_pt(y, z, t=0.0, sign=1):
    """Point on the (right/left) arm plane at world (y, z), offset t along its normal."""
    y = np.asarray(y, float); z = np.asarray(z, float)
    y, z, t = np.broadcast_arrays(y, z, np.asarray(t, float))
    p = np.stack([PLANE_A + PLANE_B * y + PLANE_C * z, y, z], -1) + t[..., None] * PANEL_N
    if sign < 0:
        p = p * np.array([-1.0, 1.0, 1.0])
    return p


# =====================================================================================
# 2D HELPERS
# =====================================================================================
def arc_pts(c, r, a0, a1, step):
    n = max(2, int(math.ceil(abs(a1 - a0) * r / step)) + 1)
    a = np.linspace(a0, a1, n)
    return np.stack([c[0] + r * np.cos(a), c[1] + r * np.sin(a)], -1)


def hermite(p0, p1, m0, m1, t):
    t = np.asarray(t, float)
    t2 = t * t; t3 = t2 * t
    return ((2 * t3 - 3 * t2 + 1) * p0 + (t3 - 2 * t2 + t) * m0 +
            (-2 * t3 + 3 * t2) * p1 + (t3 - t2) * m1)


def smoothstep(e0, e1, x):
    t = np.clip((np.asarray(x, float) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def soft_ramp(x, a, b, bl):
    """0 -> 1 between a and b: linear in the middle, C1 quadratic blends of length bl."""
    t = np.asarray(x, float) - a
    L = b - a
    m = 1.0 / (L - bl)
    return np.where(t <= 0, 0.0,
           np.where(t <= bl, m * t * t / (2 * bl),
           np.where(t <= L - bl, m * (t - bl / 2),
           np.where(t <= L, 1.0 - m * (L - t) ** 2 / (2 * bl), 1.0))))


def dedup(pts, tol=1e-6):
    pts = np.asarray(pts, float)
    keep = [0]
    for i in range(1, len(pts)):
        if np.linalg.norm(pts[i] - pts[keep[-1]]) > tol:
            keep.append(i)
    return pts[keep]


def densify(pts, maxlen, closed=False):
    pts = np.asarray(pts, float)
    out = []
    n = len(pts)
    for i in range(n if closed else n - 1):
        a = pts[i]; b = pts[(i + 1) % n]
        k = max(1, int(math.ceil(np.linalg.norm(b - a) / maxlen)))
        for j in range(k):
            out.append(a + (b - a) * j / k)
    if not closed:
        out.append(pts[-1])
    return np.array(out)


def pip(pts, poly):
    """Even-odd point-in-polygon, vectorised over pts."""
    pts = np.asarray(pts, float)
    x = pts[:, 0]; y = pts[:, 1]
    inside = np.zeros(len(pts), bool)
    px = poly[:, 0]; py = poly[:, 1]
    qx = np.roll(px, -1); qy = np.roll(py, -1)
    for i in range(len(poly)):
        y1 = py[i]; y2 = qy[i]
        if y1 == y2:
            continue
        cond = (y1 > y) != (y2 > y)
        xint = px[i] + (y - y1) * (qx[i] - px[i]) / (y2 - y1)
        inside ^= cond & (x < xint)
    return inside


def poly_area(poly):
    x = poly[:, 0]; y = poly[:, 1]
    return 0.5 * np.sum(x * np.roll(y, -1) - np.roll(x, -1) * y)


def clip_halfplane(poly, n, c):
    """Sutherland-Hodgman: keep points with n.p >= c."""
    out = []
    m = len(poly)
    for i in range(m):
        p = poly[i]; q = poly[(i + 1) % m]
        dp = n @ p - c; dq = n @ q - c
        if dp >= 0:
            out.append(p)
        if (dp >= 0) != (dq >= 0):
            t = dp / (dp - dq)
            out.append(p + (q - p) * t)
    return np.array(out)


def triangulate_domain(outline, holes, steiner_step=None, keep_dist=0.5):
    """CDT of an outline with holes (+ optional lattice Steiner points).
    Returns (verts2d, tris) with CCW triangles covering the region only."""
    loops = [outline] + list(holes)
    verts = []; edges = []
    for L in loops:
        b = len(verts); n = len(L)
        verts.extend(L.tolist())
        edges.extend([(b + i, b + (i + 1) % n) for i in range(n)])
    if steiner_step:
        mn = outline.min(0); mx = outline.max(0)
        dz = steiner_step * math.sqrt(3) / 2
        rows = []
        for j, zz in enumerate(np.arange(mn[1], mx[1] + dz, dz)):
            ws = np.arange(mn[0] + (steiner_step / 2 if j % 2 else 0), mx[0], steiner_step)
            rows.append(np.stack([ws, np.full_like(ws, zz)], -1))
        S = np.vstack(rows)
        S = S[pip(S, outline)]
        for H in holes:
            hm = H.min(0) - 1e-6; hx = H.max(0) + 1e-6
            near = np.all((S >= hm) & (S <= hx), axis=1)
            if near.any():
                inside = np.zeros(len(S), bool)
                inside[near] = pip(S[near], H)
                S = S[~inside]
        bnd = np.array(verts)
        kd = KDTree(len(bnd))
        for i, p in enumerate(bnd):
            kd.insert((p[0], p[1], 0.0), i)
        kd.balance()
        keep = np.array([kd.find((p[0], p[1], 0.0))[2] >= keep_dist * steiner_step for p in S], bool)
        verts.extend(S[keep].tolist())
    res = mgeo.delaunay_2d_cdt([Vector(p) for p in verts], edges, [], 0, 1e-7)
    ov = np.array([[v.x, v.y] for v in res[0]])
    tris = np.array([f for f in res[2] if len(f) == 3], dtype=np.int64)
    a = ov[tris[:, 0]]; b = ov[tris[:, 1]]; c = ov[tris[:, 2]]
    area = (b - a)[:, 0] * (c - a)[:, 1] - (b - a)[:, 1] * (c - a)[:, 0]
    neg = area < 0
    tris[neg] = tris[neg][:, [0, 2, 1]]
    # Classify triangles per region: flood-fill across non-constraint edges, then test
    # the largest triangle of each region (robust against slivers on the boundary).
    cons = set()
    for (e, orig) in zip(res[1], res[4]):
        if len(orig):
            cons.add((min(e), max(e)))
    owner = {}
    for ti, (p, q, r) in enumerate(tris):
        for (u, v) in ((p, q), (q, r), (r, p)):
            owner.setdefault((min(u, v), max(u, v)), []).append(ti)
    comp = -np.ones(len(tris), np.int64)
    ncomp = 0
    for seed in range(len(tris)):
        if comp[seed] >= 0:
            continue
        comp[seed] = ncomp
        stack = [seed]
        while stack:
            t = stack.pop()
            p, q, r = tris[t]
            for (u, v) in ((p, q), (q, r), (r, p)):
                k = (min(u, v), max(u, v))
                if k in cons:
                    continue
                for o in owner[k]:
                    if comp[o] < 0:
                        comp[o] = ncomp
                        stack.append(o)
        ncomp += 1
    cen = (a + b + c) / 3.0
    keep_comp = np.zeros(ncomp, bool)
    for ci in range(ncomp):
        idx = np.where(comp == ci)[0]
        t = idx[np.argmax(np.abs(area[idx]))]
        pt = cen[t:t + 1]
        ok = bool(pip(pt, outline)[0])
        for H in holes:
            if ok and np.all(pt[0] >= H.min(0)) and np.all(pt[0] <= H.max(0)) and pip(pt, H)[0]:
                ok = False
        keep_comp[ci] = ok
    tris = tris[keep_comp[comp]]
    used = np.unique(tris)
    remap = -np.ones(len(ov), np.int64)
    remap[used] = np.arange(len(used))
    return ov[used], remap[tris]


# =====================================================================================
# 3D MESH HELPERS
# =====================================================================================
def signed_volume(verts, faces):
    v = np.asarray(verts)
    tot = 0.0
    for f in faces:
        a = v[f[0]]
        for i in range(1, len(f) - 1):
            tot += np.dot(a, np.cross(v[f[i]], v[f[i + 1]]))
    return tot / 6.0


def prism_mesh(tris, top3, bot3):
    """Closed solid from a triangulated 2D region: 'top' copy uses the CCW triangles,
    'bottom' copy is reversed, boundary edges are stitched with quads."""
    n = len(top3)
    verts = np.vstack([top3, bot3])
    faces = [(int(a), int(b), int(c)) for a, b, c in tris]
    faces += [(int(a) + n, int(c) + n, int(b) + n) for a, b, c in tris]
    de = set()
    for a, b, c in tris:
        de.update([(int(a), int(b)), (int(b), int(c)), (int(c), int(a))])
    for (a, b) in de:
        if (b, a) not in de:
            faces.append((b, a, a + n)); faces.append((b, a + n, b + n))
    if signed_volume(verts, faces) < 0:
        faces = [tuple(reversed(f)) for f in faces]
    return verts, faces


def sweep_mesh(R):
    """Closed tube through stations R (m, k, 3), capped (fan-triangulated) at both ends.
    All triangles, so mirrored copies triangulate identically."""
    m, k, _ = R.shape
    verts = R.reshape(-1, 3)
    faces = []
    for i in range(m - 1):
        for j in range(k):
            a = i * k + j; b = i * k + (j + 1) % k
            faces.append((a, b, b + k)); faces.append((a, b + k, a + k))
    for j in range(1, k - 1):
        faces.append((0, j + 1, j))
        e = (m - 1) * k
        faces.append((e, e + j, e + j + 1))
    if signed_volume(verts, faces) < 0:
        faces = [tuple(reversed(f)) for f in faces]
    return verts, faces


def get_coll(name, parent=None):
    c = bpy.data.collections.get(name)
    if c is None:
        c = bpy.data.collections.new(name)
        (parent or bpy.context.scene.collection).children.link(c)
    return c


def make_obj(name, verts, faces, coll):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(map(float, v)) for v in verts], [], [tuple(f) for f in faces])
    me.validate(clean_customdata=False)
    me.update()
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    return ob


def mesh_report(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    nonman = sum(1 for e in bm.edges if not e.is_manifold)
    flipped = sum(1 for e in bm.edges if e.is_manifold and not e.is_contiguous)
    vol = bm.calc_volume(signed=True)
    bm.verts.ensure_lookup_table()
    seen = set(); parts = 0
    for v in bm.verts:
        if v.index in seen:
            continue
        parts += 1
        stack = [v]
        seen.add(v.index)
        while stack:
            u = stack.pop()
            for e in u.link_edges:
                o = e.other_vert(u)
                if o.index not in seen:
                    seen.add(o.index); stack.append(o)
    r = dict(name=ob.name, verts=len(bm.verts), faces=len(bm.faces), non_manifold=nonman,
             inconsistent=flipped, volume=round(vol, 2), parts=parts)
    bm.free()
    return r


def finalize_triangles(ob, eps=1e-9):
    """The Manifold boolean returns large n-gons with collinear vertices; triangulating
    those naively (ear clipping) gives zero-area triangles that STL checkers flag as open
    edges.  Each n-gon is re-triangulated with a constrained Delaunay triangulation in its
    own plane (never produces zero-area triangles from collinear boundary points)."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    # edges the boolean left shorter than 0.2 um collapse in float32 STL: collapse them here
    # (connected vertices only, so separate surfaces are never merged)
    bmesh.ops.dissolve_degenerate(bm, dist=2e-4, edges=bm.edges[:])
    jobs = []
    for f in [f for f in bm.faces if len(f.verts) > 3]:
        vs = list(f.verts)
        co = np.array([v.co[:] for v in vs])
        nrm = np.zeros(3)                                       # Newell normal
        for i in range(len(co)):
            a = co[i]; b = co[(i + 1) % len(co)]
            nrm += [(a[1] - b[1]) * (a[2] + b[2]), (a[2] - b[2]) * (a[0] + b[0]), (a[0] - b[0]) * (a[1] + b[1])]
        nrm /= max(np.linalg.norm(nrm), 1e-30)
        k = int(np.argmax(np.linalg.norm(co - co[0], axis=1)))
        e1 = co[k] - co[0]; e1 -= nrm * (e1 @ nrm); e1 /= max(np.linalg.norm(e1), 1e-30)
        e2 = np.cross(nrm, e1)
        p2 = [Vector((float((c - co[0]) @ e1), float((c - co[0]) @ e2))) for c in co]
        res = mgeo.delaunay_2d_cdt(p2, [], [list(range(len(vs)))], 1, 1e-12, True)
        if len(res[0]) != len(vs):
            continue                                            # leave to the fallback
        idx = [o[0] for o in res[3]]
        tris = []
        for t in res[2]:
            tv = [vs[idx[i]] for i in t]
            a, b, c = (np.array(v.co[:]) for v in tv)
            if np.cross(b - a, c - a) @ nrm < 0:
                tv = tv[::-1]
            tris.append(tv)
        jobs.append((f, tris))
    for f, tris in jobs:
        vs = list(f.verts)
        bm.faces.remove(f)
        made = []
        try:
            for tv in tris:
                made.append(bm.faces.new(tv))
        except ValueError:                                      # would duplicate a face:
            for m in made:                                      # keep the n-gon instead
                bm.faces.remove(m)
            bm.faces.new(vs)
    rest = [f for f in bm.faces if len(f.verts) > 3]
    if rest:
        bmesh.ops.triangulate(bm, faces=rest, quad_method='BEAUTY', ngon_method='BEAUTY')
    # Where two faces meet at a crease carrying nearly collinear vertices A-B-C, each side
    # can emit the same sliver ABC: a back-to-back zero-area pair.  Remove both, then the
    # orphaned crease vertex B; the diagonal AC already joins the two sides.
    seen = {}
    pairs = []
    for f in bm.faces:
        key = tuple(sorted(v.index for v in f.verts))
        if key in seen:
            pairs.append((seen[key], f))
        else:
            seen[key] = f
    for a, b in pairs:                      # a back-to-back duplicate is never valid geometry
        if a.is_valid and b.is_valid:
            bm.faces.remove(a); bm.faces.remove(b)
    loose = [e for e in bm.edges if not e.link_faces]
    for e in loose:
        bm.edges.remove(e)
    for v in [v for v in bm.verts if not v.link_edges]:
        bm.verts.remove(v)
    # micro-triangles (edges ~0.1 um) where several cutters meet: collapse them
    tiny = [f for f in bm.faces if f.calc_area() < eps]
    if tiny:
        edges = list({e for f in tiny for e in f.edges})
        bmesh.ops.dissolve_degenerate(bm, dist=5e-4, edges=edges)
        rest = [f for f in bm.faces if len(f.verts) > 3]
        if rest:
            bmesh.ops.triangulate(bm, faces=rest, quad_method='BEAUTY', ngon_method='BEAUTY')
    left = sum(1 for f in bm.faces if f.calc_area() < eps)
    bm.to_mesh(ob.data)
    ob.data.update()
    bm.free()
    return left


def bool_apply(target, cutter, op):
    mod = target.modifiers.new(name="tmp_bool", type='BOOLEAN')
    mod.operation = op
    mod.solver = 'MANIFOLD'
    mod.object = cutter
    dg = bpy.context.evaluated_depsgraph_get()
    dg.update()
    ev = target.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
    target.modifiers.remove(mod)
    old = target.data
    target.data = me
    me.name = target.name
    bpy.data.meshes.remove(old)


def sweep_obj(name, stations, coll, sign=1):
    R = np.array(stations, float)
    if sign < 0:
        R = R * np.array([-1.0, 1.0, 1.0])
    verts, faces = sweep_mesh(R)
    return make_obj(name, verts, faces, coll)


# =====================================================================================
# LENS OUTLINE (domain)
# =====================================================================================
def notch_right(zb, height, step=0.3):
    """Front-view notch from the apex (x=0) down to the end of the right flare."""
    ra = NOTCH_APEX_R; b = math.radians(NOTCH_SIDE_ANG); rf = NOTCH_FLARE_R
    zc = zb + height - ra
    n1 = np.array([math.cos(b), math.sin(b)])
    T1 = np.array([0.0, zc]) + ra * n1
    xf = T1[0] + (rf - math.sin(b) * (zb + rf - T1[1])) / math.cos(b)
    Cf = np.array([xf, zb + rf])
    T2 = Cf - rf * n1
    p1 = arc_pts((0.0, zc), ra, math.pi / 2, b, step)
    k = max(2, int(np.linalg.norm(T2 - T1) / step) + 1)
    p2 = np.linspace(T1, T2, k)
    p3 = arc_pts(Cf, rf, b + math.pi, 1.5 * math.pi, step)
    return dedup(np.vstack([p1, p2, p3]))


def side_zlow():
    return Z_BOT + (BOTTOM_RISE_TURN1 if has('c') else 0.0)


def side_bottom_curve():
    """Side-view (y, z) bottom edge of the side panel from the turn end to the merge point.
    It is written as S(y) = band_bottom(y) - G(y) with G a monotone Hermite gap, so the
    S-curve can never cross the arm's lower edge and flows into it tangentially."""
    zlow = side_zlow()
    yc = float(y_corner(zlow)[0])
    if not has('d'):
        yy = np.arange(yc, Y_MERGE, 0.8)
        return np.stack([np.append(yy, Y_MERGE), np.full(len(yy) + 1, zlow)], -1)
    ys0 = yc + SIDE_FLAT
    flat = np.arange(yc, ys0, 0.6)
    L = Y_MERGE - ys0
    tt = np.linspace(0, 1, int(L / 0.5) + 2)
    yy = ys0 + tt * L
    G0 = float(band_bottom(ys0)) - zlow
    m0 = float(d_band_bottom(ys0)) * L                 # S'(ys0) = 0
    G = hermite(G0, PANEL_MERGE_GAP, m0, 0.0, tt)
    zz = band_bottom(yy) - G
    return dedup(np.vstack([np.stack([flat, np.full_like(flat, zlow)], -1),
                            np.stack([yy, zz], -1)]))


def side_bottom_S(y):
    """Panel bottom z at world y (side region); -inf in front, +inf behind the merge."""
    sb = side_bottom_curve()
    y = np.asarray(y, float)
    z = np.interp(y, sb[:, 0], sb[:, 1])
    z = np.where(y < sb[0, 0], -1e9, z)
    return np.where(y > sb[-1, 0], 1e9, z)


def outline_right():
    """Right half of the lens outline in the (w, z) domain, from the bottom centre
    (w = 0) round the right side to the top centre (w = 0).  CCW sense."""
    zb = Z_BOT
    segs = []
    # -- 1/2: front bottom edge, designed in the front view (x, z) --
    if has('c'):
        zd = Z_BOT - BOTTOM_TRIM                  # designed below Z_BOT, trimmed flat later
        nt = notch_right(zd, NOTCH_HEIGHT + BOTTOM_TRIM)
        x_fl = float(nt[-1, 0])
        zA = zb + BOTTOM_RISE_TURN0
        xA = float(_sec(zA)['Xc'][0])
        xs = np.arange(x_fl, BOTTOM_FLAT_X, 0.6)
        flat = np.stack([xs, np.full_like(xs, zd)], -1)
        xr = np.linspace(BOTTOM_FLAT_X, xA, 40)
        rise = np.stack([xr, zd + (zA - zd) * ((xr - BOTTOM_FLAT_X) / (xA - BOTTOM_FLAT_X)) ** 2], -1)
        fv = dedup(np.vstack([nt, flat, rise]))
        slope_A = 2 * (zA - zd) / (xA - BOTTOM_FLAT_X)
    else:
        zA = zb
        xA = float(_sec(zA)['Xc'][0])
        xs = np.arange(0.0, xA, 0.8)
        fv = np.vstack([np.stack([xs, np.full_like(xs, zb)], -1), [[xA, zb]]])
        slope_A = 0.0
    w = w_from_front(fv[:, 0], fv[:, 1])
    w[-1] = XC_REF
    segs.append(np.stack([w, fv[:, 1]], -1))
    # -- 3: the turn, directly in the domain --
    zlow = side_zlow()
    mA = slope_A * float(_sec(zA)['Xc'][0]) / XC_REF
    t = np.linspace(0, 1, 16)
    zt = hermite(zA, zlow, mA * LC_REF, 0.0, t)
    segs.append(np.stack([XC_REF + t * LC_REF, zt], -1))
    # -- 4: side panel bottom edge (side view), then its rear end at the merge point --
    side = side_bottom_curve()
    z_m = float(side[-1, 1])
    ztop_m = float(z_topline_build(Y_MERGE)) + TOPM
    zz = np.linspace(z_m, ztop_m, max(2, int((ztop_m - z_m) / 0.6) + 1))
    rear = np.stack([np.full_like(zz, Y_MERGE), zz], -1)
    # -- 5: top of the side panel (forward), then across the front --
    zt_front = Z_TOP + TOPM
    y_ct = float(y_corner(zt_front)[0])
    yy = np.linspace(Y_MERGE, y_ct, max(2, int((Y_MERGE - y_ct) / 0.8) + 1))
    top_side = np.stack([yy, z_topline_build(yy) + TOPM], -1)
    sv = dedup(np.vstack([side, rear[1:], top_side[1:]]))
    ws = w_from_side(sv[:, 0], sv[:, 1])
    segs.append(np.stack([ws, sv[:, 1]], -1))
    wf = np.linspace(WC0, 0.0, int(WC0 / 0.8) + 2)
    segs.append(np.stack([wf, np.full_like(wf, zt_front)], -1))
    return dedup(np.vstack(segs), 1e-5)


def lens_outline():
    R = outline_right()
    Lm = R[::-1].copy()
    Lm[:, 0] *= -1                                   # top centre -> left side -> bottom centre
    full = np.vstack([R[:-1], Lm[:-1]])
    full = densify(full, 0.7, closed=True)
    full = dedup(full, 1e-5)
    if np.linalg.norm(full[0] - full[-1]) < 1e-5:
        full = full[:-1]
    if poly_area(full) < 0:
        full = full[::-1]
    return full


# =====================================================================================
# HOLES (domain polygons)
# =====================================================================================
def hole_poly(wc, zc, diam, nseg):
    """Polygon in the domain that maps to a true circle (circumscribing diam) on the surface."""
    P, N, Pw, Pz = surf_PN(np.array([wc]), np.array([zc]))
    N = N[0]; Pw = Pw[0]; Pz = Pz[0]
    e1 = Pw / np.linalg.norm(Pw)
    e2 = np.cross(N, e1)
    r = diam / 2.0 / math.cos(math.pi / nseg)
    J = np.stack([Pw, Pz], 1)                         # 3x2
    pinv = np.linalg.solve(J.T @ J, J.T)              # 2x3
    a = np.linspace(0, 2 * math.pi, nseg, endpoint=False)
    off3 = r * (np.cos(a)[:, None] * e1 + np.sin(a)[:, None] * e2)
    return np.array([wc, zc]) + off3 @ pinv.T


def pinhole_centres_xz():
    pts = []
    dz = PIN_PITCH * math.sqrt(3) / 2
    a = PIN_ZONE_W / 2.0; bz = PIN_ZONE_H / 2.0
    ez = Z_MID + EYE_Z
    nrow = int(bz / dz) + 1
    ncol = int(a / PIN_PITCH) + 2
    for side in (-1, 1):
        cx = side * EYE_X
        for j in range(-nrow, nrow + 1):
            zz = ez + j * dz
            off = PIN_PITCH / 2 if (j % 2) else 0.0
            for i in range(-ncol, ncol + 1):
                xx = cx + i * PIN_PITCH + off
                if ((xx - cx) / a) ** 2 + ((zz - ez) / bz) ** 2 <= 1.0 + 1e-9:
                    pts.append((xx, zz))
    return pts


def pinhole_domain():
    out = []
    for (x, z) in pinhole_centres_xz():
        w = float(w_from_front(abs(x), z)[0]) * (1 if x >= 0 else -1)
        out.append((w, z))
    return out


def joint_pin_positions():
    """(y, z) world positions of the lap-joint pins (right side; mirror x for left)."""
    ys = [float(y_arm_front(Z_TOP)[0]) + JOINT_PIN_FRONT, Y_REAR - JOINT_PIN_REAR]
    res = []
    for y in ys:
        ang = math.atan(-float(dz_baseline(y)))
        z = float(z_baseline(y)) - 0.5 * ARM_H0 / math.cos(ang)
        res.append((y, z))
    return res


def plane_circle(y, z, diam, nseg, sign=1):
    """True circle on the arm plane, centred at world (y, z): returns its (y, z) polygon
    (the plane's parametrisation) and the in-plane frame."""
    n = PANEL_N
    e1 = np.array([0.0, 1.0, 0.0]) - n[1] * n
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(n, e1)
    c = plane_pt(y, z)
    r = diam / 2 / math.cos(math.pi / nseg)
    a = np.linspace(0, 2 * math.pi, nseg, endpoint=False)
    pts = c + r * (np.cos(a)[:, None] * e1 + np.sin(a)[:, None] * e2)
    return pts[:, 1:3]


# =====================================================================================
# LENS SOLIDS
# =====================================================================================
def cylinder_mesh(c, d, r, nseg, t0, t1):
    """Closed n-gon prism: centre c, unit axis d, from c + t0*d to c + t1*d."""
    d = np.asarray(d, float); d = d / np.linalg.norm(d)
    ref = np.array([0.0, 0.0, 1.0]) if abs(d[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
    e1 = np.cross(d, ref); e1 /= np.linalg.norm(e1)
    e2 = np.cross(d, e1)
    a = np.linspace(0, 2 * math.pi, nseg, endpoint=False)
    ring = r * (np.cos(a)[:, None] * e1 + np.sin(a)[:, None] * e2)
    lo = c + t0 * d + ring; hi = c + t1 * d + ring
    verts = np.vstack([lo, hi])
    faces = []
    for i in range(nseg):
        j = (i + 1) % nseg
        faces += [(i, j, nseg + j), (i, nseg + j, nseg + i)]
    for i in range(1, nseg - 1):
        faces += [(0, i + 1, i), (nseg, nseg + i, nseg + i + 1)]
    if signed_volume(verts, faces) < 0:
        faces = [tuple(reversed(f)) for f in faces]
    return verts, faces


def build_pinhole_cutters(coll):
    """Vision pinholes, each drilled along the line from the wearer's eye (EYE_X, EYE_DEPTH,
    eye height) through the hole centre, so every hole is open along its line of sight."""
    V = []; F = []
    for (w, z) in pinhole_domain():
        P = surf_P(np.array([w]), np.array([z]))[0]
        E = np.array([math.copysign(EYE_X, P[0]), EYE_DEPTH, Z_MID + EYE_Z])
        d = P - E
        r = PIN_D / 2 / math.cos(math.pi / PIN_SEGS)
        v, f = cylinder_mesh(P, d, r, PIN_SEGS, -5.0, 3.0)
        F += [tuple(i + len(V) for i in fa) for fa in f]
        V += v.tolist()
    return make_obj("tmp_Pinholes", np.array(V), F, coll)


def build_shell(coll):
    outline = lens_outline()
    holes = []
    pin_report = None
    if has('f'):
        cen = pinhole_domain()
        kd = KDTree(len(outline))
        for i, p in enumerate(outline):
            kd.insert((p[0], p[1], 0.0), i)
        kd.balance()
        dmin = min(kd.find((w, z, 0.0))[2] for (w, z) in cen) - PIN_D / 2
        pin_report = dict(count=len(cen), min_edge_clearance=round(dmin, 2))
        if dmin < PIN_EDGE_MARGIN:
            print("WARNING: pinhole closer than PIN_EDGE_MARGIN to an edge:", dmin)
    dv, tris = triangulate_domain(outline, holes, steiner_step=MESH_STEP, keep_dist=0.5)
    P, N, _, _ = surf_PN(dv[:, 0], dv[:, 1])
    verts, faces = prism_mesh(tris, P, P - WALL * N)
    ob = make_obj("CoverupLens", verts, faces, coll)
    return ob, outline, pin_report


def deck_depth(aw):
    aw = np.asarray(aw, float)
    w_end = WC0 + PANEL_LENGTH
    d = DECK_DEPTH_C + (DECK_DEPTH_TURN - DECK_DEPTH_C) * smoothstep(38.0, XC_REF - 2.0, aw)
    # (round the turn the inner edge is a Hermite corner, see deck_inner)
    d = d + (DECK_DEPTH_SEAM - DECK_DEPTH_TURN) * smoothstep(WC0, WC0 + 0.8, aw)
    # ... and narrow straight after the hinge cap, so the temples keep their head clearance
    d = d + (DECK_DEPTH_SIDE - DECK_DEPTH_SEAM) * smoothstep(W_SEAM - 0.3, W_SEAM + 1.5, aw)
    lin = np.clip((aw - (W_SEAM + 10.0)) / (w_end - (W_SEAM + 10.0)), 0, 1)
    d = d + (DECK_DEPTH_REAR - DECK_DEPTH_SIDE) * smoothstep(0.55, 1.0, lin)
    return d


def _top_z_for_w(ws, fn=None):
    fn = z_baseline if fn is None else fn
    zt = np.full_like(np.asarray(ws, float), Z_TOP)
    for _ in range(4):
        P = surf_P(ws, zt)
        zt = fn(P[:, 1])
    return zt


def _edge_frame(ws, fn=None):
    """Outer top-edge points and horizontal outward normals at stations ws."""
    zt = _top_z_for_w(ws, fn)
    P, N, _, _ = surf_PN(ws, zt)
    nh = N.copy(); nh[:, 2] = 0.0
    nh /= np.linalg.norm(nh, axis=1, keepdims=True)
    return P, nh, zt


def deck_inner(ws):
    """Plan (x, y) of the deck's inner (rear) edge for stations ws: the outer edge offset
    by deck_depth, except round the turn, where a Hermite curve joins the front and side
    offsets (so the deck can be deeper than CORNER_R without the offset folding over)."""
    ws = np.asarray(ws, float)
    aw = np.abs(ws)
    P, nh, _ = _edge_frame(aw)
    q = P[:, :2] - deck_depth(aw)[:, None] * nh[:, :2]
    wa, wb = XC_REF - DECK_CORNER_IN, WC0 + DECK_CORNER_OUT

    def raw(w):
        Pr, nr, _ = _edge_frame(w)
        return Pr[:, :2] - deck_depth(w)[:, None] * nr[:, :2]
    ea = raw(np.array([wa - 0.05, wa, wa + 0.05]))
    eb = raw(np.array([wb - 0.05, wb, wb + 0.05]))
    L = wb - wa
    m = (aw > wa) & (aw < wb)
    t = ((aw[m] - wa) / L)[:, None]
    chord = float(np.linalg.norm(eb[1] - ea[1]))
    ta = ea[2] - ea[0]; ta = ta / np.linalg.norm(ta) * chord * DECK_CORNER_K
    tb = eb[2] - eb[0]; tb = tb / np.linalg.norm(tb) * chord * DECK_CORNER_K
    q[m] = hermite(ea[1][None], eb[1][None], ta[None], tb[None], t)
    q[:, 0] *= np.where(ws < 0, -1.0, 1.0)
    return q


def deck_rise(aw):
    """Height of the deck top's rear edge above the brow edge: DECK_RISE over the front,
    fading to 0 ahead of the hinge cap, so the cap's inner face stands its full height over a
    level deck (and the side lips are level across)."""
    w0, w1 = cap_range()
    aw = np.asarray(aw, float)
    # the rear edge sits further back toward the corners (so it reads higher from the front):
    # ease the rise off there, leaving the shallow dip beside the caps seen in the front photo
    ease = 1.0 - DECK_RISE_EASE * smoothstep(30.0, w0 - DECK_RISE_FADE[0], aw)
    return DECK_RISE * ease * (1.0 - smoothstep(w0 - DECK_RISE_FADE[0], w0 - DECK_RISE_FADE[1], aw))


def build_deck(coll):
    y_end = (Y_REAR if has('g') else Y_MERGE) - DECK_REAR_INSET
    w_end = float(w_from_side(y_end, float(z_baseline(y_end)))[0])
    n = int(2 * w_end / 0.3) + 1
    ws = np.linspace(-w_end, w_end, n)
    Pt, nh, zt = _edge_frame(ws)                       # base top line (no joint bump)
    zbld = _top_z_for_w(ws, z_topline_build)
    Phi, Nhi, _, _ = surf_PN(ws, zbld + TOPM)
    q = deck_inner(ws)
    Dh = np.linalg.norm(Pt[:, :2] - q, axis=1)
    rise = deck_rise(np.abs(ws))
    # 45-deg wedge under the deck (hidden): from the deck's inner lower edge down to the
    # wall, so the upright print needs no support under the brow
    # (front and corners only: along the temples the lip is short and a wedge would eat into
    # the head clearance)
    fw = 1.0 - smoothstep(W_SEAM - 0.3, W_SEAM + 1.5, np.abs(ws))
    z_w = zt + rise - DECK_T - fw * (Dh - 0.5 * WALL)
    Pw, Nw, _, _ = surf_PN(ws, z_w)
    v0 = Pw - 0.5 * WALL * Nw
    v1 = Phi - 0.5 * WALL * Nhi
    v2 = np.column_stack([q, zbld + TOPM + rise])       # built tall, trimmed by the cutters
    v3 = np.column_stack([q, zt + rise - DECK_T])       # constant thickness under the sloped top
    R = np.stack([v0, v1, v2, v3], axis=1)
    verts, faces = sweep_mesh(R)
    return make_obj("tmp_Deck", verts, faces, coll)


def _xz_prism(name, poly, coll, X=130.0):
    """Prism along x from a (y, z) polygon."""
    if poly_area(poly) < 0:
        poly = poly[::-1]
    dv, tris = triangulate_domain(poly, [])
    top3 = np.stack([np.full(len(dv), X), dv[:, 0], dv[:, 1]], -1)
    bot3 = np.stack([np.full(len(dv), -X), dv[:, 0], dv[:, 1]], -1)
    verts, faces = prism_mesh(tris, top3, bot3)
    return make_obj(name, verts, faces, coll)


def build_top_cutter(coll):
    """Side / temple top line (prism across x).  In front of Y_JOIN it stands clear: the
    brow deck there is trimmed by build_deck_top_cutter."""
    ys = Y_JOIN - 0.05
    yy = np.append(np.arange(Y_JOIN, Y_JOIN + TOP_BUMP_LEN + DECK_SLOPE_BLEND + 2.0, 0.5), 260.0)
    top = np.stack([yy, z_topline(yy)], -1)
    hi = Z_TOP + 8.0
    poly = np.vstack([[[-80.0, hi], [ys, hi], [ys, float(z_topline(ys))]], top,
                      [[260.0, 120.0], [-80.0, 120.0]]])
    return _xz_prism("tmp_TopCut", poly, coll)


def build_deck_top_cutter(coll):
    """Brow deck top: along every station the cut runs straight from the crisp outer edge
    (at Z_TOP) up to the deck's rear edge (deck_rise higher), extended 2 mm past both, so the
    deck slopes down toward the front.  Ends at Y_JOIN on the sides (under the hinge cap)."""
    w_e = WC0 + (Y_JOIN - float(y_corner(Z_TOP)[0]))
    ws = np.linspace(-w_e, w_e, int(2 * w_e / 0.3) + 1)
    P, nh, _ = _edge_frame(ws)
    q = deck_inner(ws)
    d = P[:, :2] - q
    Dh = np.linalg.norm(d, axis=1)
    u = np.column_stack([d / Dh[:, None], np.zeros(len(ws))])      # horizontal, outward
    rise = deck_rise(np.abs(ws))
    s = (rise / Dh)[:, None]
    up = np.array([0.0, 0.0, 1.0])
    q3 = np.column_stack([q, np.full(len(ws), Z_TOP) + rise])
    a = P + 2.0 * u - 2.0 * s * up
    b = q3 - 2.0 * u + 2.0 * s * up
    st = np.stack([a, b, b + (Z_TOP + 9.0 - b[:, 2:3]) * up, a + (Z_TOP + 9.0 - a[:, 2:3]) * up], 1)
    verts, faces = sweep_mesh(st)
    return make_obj("tmp_DeckTopCut", verts, faces, coll)


def build_bottom_cutter(coll):
    poly = np.array([[-80.0, Z_BOT - 30.0], [260.0, Z_BOT - 30.0], [260.0, Z_BOT], [-80.0, Z_BOT]])
    return _xz_prism("tmp_BottomCut", poly, coll)


def build_brow_facet_cutter(coll):
    """Optional narrow 45-deg facet between the brow face and the deck top, following the
    plan curve across the front and round the turns (both edges stay sharp)."""
    h = BROW_FACET_H
    w_end = W_SEAM - SEAM_WIDTH / 2 - HINGE_SEAM_GAP - HINGE_LEN - 0.5
    ws = np.linspace(-w_end, w_end, int(2 * w_end / 0.4) + 1)
    P0, N0, _, _ = surf_PN(ws, np.full_like(ws, Z_TOP))
    nh = N0.copy(); nh[:, 2] = 0
    nh /= np.linalg.norm(nh, axis=1, keepdims=True)
    Pl, Nl, _, _ = surf_PN(ws, np.full_like(ws, Z_TOP - h))
    up = np.array([0, 0, 1.0])
    a = Pl + 0.0 * Nl                                    # facet lower line on the face
    b = P0 - h * nh                                      # facet upper line on the deck top
    st = np.stack([a - 0.02 * nh, b + 0.02 * up, b + 3.0 * up + 3.0 * nh, a + 3.0 * nh - 0.5 * up], 1)
    verts, faces = sweep_mesh(st)
    return make_obj("tmp_BrowFacet", verts, faces, coll)


# ---- arm inlay: joggle slab + channel cutter -----------------------------------------
def build_joggle_slab(coll, sign):
    """Inner wall the panel is joggled onto behind the arm, plus the webs that join it to
    the un-joggled panel along the channel's lower edge and front end."""
    y0 = float(y_channel_front(Z_TOP)[0]) - WALL
    ys = np.append(np.arange(y0, Y_REAR, 0.5), Y_REAR)
    bb = band_bottom(ys)
    S = side_bottom_S(ys)
    rel = np.clip(S + 0.3 - bb, -WALL, 0.3)
    k = 9                                                # smooth over +-2 mm (no saw-tooth)
    rel = np.convolve(np.pad(rel, k // 2, mode='edge'), np.ones(k) / k, mode='valid')
    z_lo = bb + rel
    # behind the merge the joggle hangs free: let its lower edge rise at ~48 deg toward the
    # rear end so the upright print has no floating island there (hidden behind the arm)
    y_a = Y_MERGE - 3.0
    z_a = float(np.interp(y_a, ys, z_lo))
    z_lo = np.where(ys > y_a, np.maximum(z_lo, z_a + 1.1 * (ys - y_a)), z_lo)
    z_hi = z_topline_build(ys) + TOPM + 1.0
    tap = 1.0 - (1.0 - JOGGLE_TAPER) * smoothstep(Y_REAR - 8.0, Y_REAR, ys)
    t_in = -(ARM_INLAY_T + ARM_LAP_GAP + JOGGLE_WALL * tap)
    t_out = np.full_like(ys, -1.0)
    # the web under the joggle is chamfered (~48 deg) on the inside, so the upright print
    # needs no support under it; the chamfer starts at the panel's inner face and passes
    # well below the channel's inner step corner, so the joggle is joined along its length
    t_b = np.full_like(ys, -(WALL - 0.05))
    z_lo_in = z_lo + 1.1 * (t_b - t_in)
    st = np.stack([plane_pt(ys, z_lo, t_out), plane_pt(ys, z_lo, t_b), plane_pt(ys, z_lo_in, t_in),
                   plane_pt(ys, z_hi, t_in), plane_pt(ys, z_hi, t_out)], 1)
    return sweep_obj("tmp_Joggle%+d" % sign, st, coll, sign)


def channel_outline():
    """(y, z) outline of the arm channel on the arm plane (right side)."""
    ztc = Z_TOP + 6.0
    zf = float(band_bottom(float(y_channel_front(Z_TOP - ARM_H0)[0])))
    for _ in range(8):                                   # front wall meets the step
        zf = float(band_bottom(float(y_channel_front(zf)[0])))
    yf = float(y_channel_front(zf)[0])
    yb = np.append(np.arange(yf, Y_REAR + 6.0, 0.5), Y_REAR + 6.0)
    bottom = np.stack([yb, band_bottom(yb)], -1)
    zs = np.linspace(ztc, zf, 30)[:-1]
    front = np.stack([y_channel_front(zs), zs], -1)
    poly = np.vstack([bottom, [[Y_REAR + 6.0, ztc]], front])
    return dedup(poly, 1e-6)


def build_channel_cutter(coll, sign):
    poly = channel_outline()
    if poly_area(poly) < 0:
        poly = poly[::-1]
    dv, tris = triangulate_domain(poly, [])
    top3 = plane_pt(dv[:, 0], dv[:, 1], 2.5)
    bot3 = plane_pt(dv[:, 0], dv[:, 1], -(ARM_INLAY_T + ARM_LAP_GAP))
    if sign < 0:
        top3 = top3 * np.array([-1.0, 1, 1]); bot3 = bot3 * np.array([-1.0, 1, 1])
    verts, faces = prism_mesh(tris, top3, bot3)
    return make_obj("tmp_Channel%+d" % sign, verts, faces, coll)


def build_joint_pin_cutters(coll):
    obs = []
    for sign in (1, -1):
        for k, (y, z) in enumerate(joint_pin_positions()):
            circ = plane_circle(y, z, JOINT_PIN_D, JOINT_PIN_SEGS)
            dv, tris = triangulate_domain(circ, [])
            top3 = plane_pt(dv[:, 0], dv[:, 1], 1.0)
            bot3 = plane_pt(dv[:, 0], dv[:, 1], -(ARM_INLAY_T + ARM_LAP_GAP + JOGGLE_WALL + 2.0))
            if sign < 0:
                top3 = top3 * np.array([-1.0, 1, 1]); bot3 = bot3 * np.array([-1.0, 1, 1])
            verts, faces = prism_mesh(tris, top3, bot3)
            obs.append(make_obj("tmp_Pin%+d_%d" % (sign, k), verts, faces, coll))
    return obs


# ---- hinge caps, seams --------------------------------------------------------------
def cap_range():
    w1 = W_SEAM - SEAM_WIDTH / 2 + 0.05 - HINGE_SEAM_GAP       # cap rear face
    return w1 - HINGE_LEN, w1


def cap_profile(w):
    """Cap top height above Z_TOP and outer chamfer along the cap: rising from the front to
    the HINGE_H_PEAK bump round the screw hole, then rounding down (zero end slope) to the
    rear face, where top and chamfer match the arm's top edge (HINGE_JOIN_H, ARM_TOP_CHAMFER)
    so the two run on with no step."""
    w0, w1 = cap_range()
    f = np.clip((np.asarray(w, float) - w0) / (w1 - w0), 0, 1)
    # quick rise at the front, then a gentle (~7 deg) climb past the hole to the peak, so the
    # top faces forward a little (as in the photos), then the rounded fall to joint level
    g = ((1.0 - HINGE_PEAK_CLIMB) * smoothstep(0.0, HINGE_PEAK_FROM, f)
         + HINGE_PEAK_CLIMB * smoothstep(HINGE_PEAK_FROM - 0.1, HINGE_PEAK_TO, f))
    h = (HINGE_H_FRONT + (HINGE_H_PEAK - HINGE_H_FRONT) * g
         - (HINGE_H_PEAK - HINGE_H_REAR) * smoothstep(HINGE_PEAK_TO, 1.0, f))
    ch = HINGE_CHAMFER + (HINGE_CHAMFER_REAR - HINGE_CHAMFER) * smoothstep(HINGE_PEAK_TO, 1.0, f)
    return h, ch


def cap_inner_height(w):
    """Cap top at its inner edge (level across the cap)."""
    return cap_profile(w)[0]


def cap_height(w):
    return cap_profile(w)[0]


def cap_chamfer(ws, h, width):
    return np.maximum(0.05, np.minimum.reduce([cap_profile(ws)[1], h - 0.05, width - 0.5]))


def cap_frame(ws):
    P0, N0, _, _ = surf_PN(ws, np.full_like(ws, Z_TOP))
    nh = N0.copy(); nh[:, 2] = 0
    nh /= np.linalg.norm(nh, axis=1, keepdims=True)
    return P0, nh


def cap_stations(n=61):
    """Outer edge stations of the cap (round the turn) and the matching inner edge points:
    the inner edge is a short front face, a diagonal, then a straight run parallel to the
    side panel, so the footprint is a clean wedge (no offset-curve cusp in the turn)."""
    w0, w1 = cap_range()
    ws = np.linspace(w0, w1, n)
    P0, nh = cap_frame(ws)
    seg = np.linalg.norm(np.diff(P0[:, :2], axis=0), axis=1)
    f = np.concatenate([[0], np.cumsum(seg)]); f /= f[-1]
    rear_in = P0[-1, :2] - HINGE_WID * nh[-1, :2]
    front_in = rear_in + np.array([0.0, -HINGE_INNER_LEN])
    start_in = P0[0, :2] - HINGE_FRONT_W * nh[0, :2]
    path = np.array([start_in, front_in, rear_in])
    pl = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(path, axis=0), axis=1))]); pl /= pl[-1]
    inner = np.stack([np.interp(f, pl, path[:, 0]), np.interp(f, pl, path[:, 1])], -1)
    return ws, P0, nh, inner


def hinge_hole_centre(sign=1):
    ws, P0, nh, inner = cap_stations()
    w0, w1 = cap_range()
    i = int(np.argmin(np.abs(ws - (w1 - HINGE_HOLE_BACK))))
    h = float(cap_height(ws[i:i + 1])[0])
    hi = float(cap_inner_height(ws[i:i + 1])[0])
    width = float(np.linalg.norm(P0[i, :2] - inner[i]))
    ch = float(cap_chamfer(ws[i:i + 1], np.array([h]), np.array([width]))[0])
    o = P0[i, :2] - ch * nh[i, :2]
    c = np.array([0.5 * (o[0] + inner[i, 0]), 0.5 * (o[1] + inner[i, 1]), Z_TOP])
    if sign < 0:
        c = c * np.array([-1.0, 1, 1])
    return c, 0.5 * (h + hi)                 # top height at the hole centre (above Z_TOP)


def build_hinge_caps(coll):
    """Corner caps over the turn, ending at the seam where the arm butts against them: a
    chamfered top rising from HINGE_H_FRONT to HINGE_H_PEAK round the screw hole (a 4 mm
    inner face over the level deck), then rounding down to the arm's top-edge height and
    chamfer at the rear face.  The outer face follows the surface above the brow edge (0.02
    proud), so it is flush with the arm's outer face."""
    ws, P0, nh, inner = cap_stations()
    Pe, Ne, _, _ = surf_PN(ws, np.full_like(ws, Z_TOP - HINGE_EMBED))
    h = cap_height(ws)
    hi = cap_inner_height(ws)
    width = np.linalg.norm(P0[:, :2] - inner, axis=1)
    ch = cap_chamfer(ws, h, width)
    up = np.array([0, 0, 1.0])
    Pu, Nu, _, _ = surf_PN(ws, Z_TOP + h - ch)
    Pc, _, _, _ = surf_PN(ws, Z_TOP + h)
    inner3 = np.column_stack([inner, np.full(len(inner), Z_TOP)])
    st = np.stack([Pe - 0.05 * Ne,
                   Pu + 0.02 * Nu,
                   Pc - ch[:, None] * nh,
                   inner3 + hi[:, None] * up,
                   inner3 - HINGE_EMBED * up], 1)
    caps, holes = [], []
    for sign in (1, -1):
        caps.append(sweep_obj("tmp_Cap%+d" % sign, st, coll, sign))
        c, hh = hinge_hole_centre(sign)
        a = np.linspace(0, 2 * math.pi, 24, endpoint=False)
        r = HINGE_HOLE_D / 2 / math.cos(math.pi / 24)
        circ = np.stack([c[0] + r * np.cos(a), c[1] + r * np.sin(a)], -1)
        dv, tris = triangulate_domain(circ, [])
        za = Z_TOP + hh - min(HINGE_HOLE_DEPTH, hh + 0.5)
        zb = Z_TOP + HINGE_H_PEAK + 1.0
        verts, faces = prism_mesh(tris, np.column_stack([dv, np.full(len(dv), zb)]),
                                  np.column_stack([dv, np.full(len(dv), za)]))
        holes.append(make_obj("tmp_CapHole%+d" % sign, verts, faces, coll))
    return caps, holes


def _surface_groove_along_z(name, wc, width, depth, z0, z1, coll, sign, taper=0.0):
    """Groove of constant width along z; with taper > 0 its depth fades in from 10 % at z0
    over that length (a closed lower end that leaves the edge outline untouched)."""
    stations = []
    for z in np.arange(z0, z1 + 1e-9, 0.25 if taper > 0 else 0.5):
        ws = wc + np.array([-width / 2, width / 2])
        P, N, _, _ = surf_PN(ws, np.full(2, z))
        d = depth * (0.1 + 0.9 * float(smoothstep(z0, z0 + taper, z))) if taper > 0 else depth
        stations.append([P[0] - d * N[0], P[1] - d * N[1], P[1] + 1.0 * N[1], P[0] + 1.0 * N[0]])
    return sweep_obj(name, stations, coll, sign)


def _surface_groove_along_w(name, zc, width, depth, wa, wb, coll, sign):
    stations = []
    for w in np.arange(wa, wb + 1e-9, 0.2):
        zs = zc + np.array([-width / 2, width / 2])
        P, N, _, _ = surf_PN(np.full(2, w), zs)
        stations.append([P[0] - depth * N[0], P[1] - depth * N[1], P[1] + 1.0 * N[1], P[0] + 1.0 * N[0]])
    return sweep_obj(name, stations, coll, sign)


def build_seam_cutters(coll):
    """Seam groove below the arm band (above it the arm/cap butt joint continues the line),
    and the outline grooves of the hinge cap on the corner surface."""
    obs = []
    zg = Z_TOP - HINGE_DROP
    w0, w1 = cap_range()
    for sign in (1, -1):
        z_top = float(band_bottom(float(y_seam(Z_TOP - ARM_H0)[0]))) + 0.3 if has('g') else Z_TOP + 2.0
        # stops just above the side bottom edge (cutting through it left a notch in the
        # side-view outline)
        obs.append(_surface_groove_along_z("tmp_Seam%+d" % sign, W_SEAM, SEAM_WIDTH, SEAM_DEPTH,
                                           side_zlow() + SEAM_END_GAP, z_top, coll, sign,
                                           taper=SEAM_END_TAPER))
        obs.append(_surface_groove_along_w("tmp_CapLow%+d" % sign, zg, CAP_GROOVE_W, CAP_GROOVE_D,
                                           w0 - CAP_GROOVE_W / 2, W_SEAM, coll, sign))
        obs.append(_surface_groove_along_z("tmp_CapFront%+d" % sign, w0, CAP_GROOVE_W, CAP_GROOVE_D,
                                           zg - CAP_GROOVE_W / 2, Z_TOP + 0.4, coll, sign))
    return obs


# =====================================================================================
# ARMS
# =====================================================================================
def _bend_shape(th, n=401):
    """Unit-length top-edge bend: tangent angle psi(u) = -a0 - th*u^(p+1)."""
    a0 = math.atan(TAN_DS)
    u = np.linspace(0, 1, n)
    psi = -a0 - th * u ** (ARM_BEND_POWER + 1)
    du = np.diff(u)
    cx = np.concatenate([[0], np.cumsum(0.5 * (np.cos(psi[1:]) + np.cos(psi[:-1])) * du)])
    cz = np.concatenate([[0], np.cumsum(0.5 * (np.sin(psi[1:]) + np.sin(psi[:-1])) * du)])
    return u, psi, cx, cz


def arm_bend_solve(run, drop, h=None):
    """Turn angle and length of the bend so that the arm centre line runs `run` and drops
    `drop` from the bend start to the extremity of the round tip."""
    h = ARM_H1 if h is None else h

    def lb_drop(th):
        u, psi, cx, cz = _bend_shape(th)
        n0 = np.array([-math.sin(psi[0]), math.cos(psi[0])])
        n1 = np.array([-math.sin(psi[-1]), math.cos(psi[-1])])
        t1 = np.array([math.cos(psi[-1]), math.sin(psi[-1])])
        Lb = (run - 0.5 * h * (t1[0] - n1[0] + n0[0])) / cx[-1]
        d = -0.5 * h * n0[1] - Lb * cz[-1] - 0.5 * h * (t1[1] - n1[1])
        return Lb, d

    lo, hi = 0.0, 2.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if lb_drop(mid)[1] < drop:
            lo = mid
        else:
            hi = mid
    th = 0.5 * (lo + hi)
    Lb, _ = lb_drop(th)
    u, psi, cx, cz = _bend_shape(th)
    return th, Lb, u, psi, cx * Lb, cz * Lb


def arm_curves(y_b0, bend):
    """Top edge, bottom edge, tangent angle and height along the arm for bend start y_b0."""
    th, Lb, u, psi_b, bx, bz = bend
    y_start = Y_SEAM_TOP - 6.0
    yy = np.arange(y_start, y_b0, 0.5)
    yy = np.append(yy, y_b0)
    te1 = np.stack([yy, z_baseline(yy)], -1)
    psi1 = np.arctan(dz_baseline(yy))
    te2 = te1[-1] + np.stack([bx, bz], -1)
    teb = np.vstack([te1, te2[1:]])                  # base top edge (the band hangs from it)
    psi = np.concatenate([psi1, psi_b[1:]])
    seg = np.linalg.norm(np.diff(teb, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)])
    s_rear = float(np.interp(Y_REAR, te1[:, 0], s[:len(te1)])) if y_b0 > Y_REAR else s[len(te1) - 1]
    # linear taper with rounded ends, about as fast as the top edge falls, so the lower edge
    # runs on nearly level behind the panel (as in the photo) instead of rising in a wave
    h = ARM_H0 + (ARM_H1 - ARM_H0) * soft_ramp(s, s_rear, s_rear + ARM_TAPER_LEN, 8.0)
    nup = np.stack([-np.sin(psi), np.cos(psi)], -1)
    be = teb - h[:, None] * nup
    te = teb.copy()
    te[:len(te1), 1] += top_bump(yy)                 # the top edge rises into the hinge cap
    return te, be, psi, h, nup, th, Lb, len(te1) - 1, teb


def arm_outline_and_length(y_b0, bend):
    te, be, psi, h, nup, th, Lb, ib, teb = arm_curves(y_b0, bend)
    t_end = np.array([math.cos(psi[-1]), math.sin(psi[-1])])
    c = te[-1] - 0.5 * h[-1] * nup[-1]
    beta = np.linspace(math.pi, 0.0, 33)
    cap = c + 0.5 * h[-1] * (np.cos(beta)[:, None] * nup[-1] + np.sin(beta)[:, None] * t_end)
    poly = np.vstack([be, cap[1:-1], te[::-1]])
    # raked front end on the seam line (butts against the hinge cap / channel front wall)
    zf1, zf2 = Z_TOP + 1.0, Z_TOP - ARM_H0 - 3.0
    yf1 = float(y_arm_front(zf1)[0]); yf2 = float(y_arm_front(zf2)[0])
    d = np.array([yf2 - yf1, zf2 - zf1]); d /= np.linalg.norm(d)
    nrm = np.array([-d[1], d[0]])
    if nrm[0] < 0:
        nrm = -nrm
    cfront = float(nrm @ np.array([yf1, zf1]))
    poly = clip_halfplane(poly, nrm, cfront)
    poly = dedup(poly, 1e-6)
    if poly_area(poly) < 0:
        poly = poly[::-1]
    cl = teb - 0.5 * h[:, None] * nup                   # centre line of the ARM_H0 band
    clk = cl[cl @ nrm >= cfront]
    hinge_c, _ = hinge_hole_centre(1)
    L = (clk[0, 0] - hinge_c[1]) + np.sum(np.linalg.norm(np.diff(clk, axis=0), axis=1)) + 0.5 * h[-1]
    tip = c + 0.5 * h[-1] * t_end
    info = dict(bend_turn_deg=round(math.degrees(th), 1),
                tip_dir_deg_below_horizontal=round(math.degrees(-psi[-1]), 1),
                bend_len_top_edge=round(float(Lb), 1),
                min_top_edge_bend_radius=round(float(Lb / (th * (ARM_BEND_POWER + 1))), 1),
                y_bend_start=round(float(y_b0), 1),
                tip_point_yz=(round(float(tip[0]), 1), round(float(tip[1]), 1)),
                centreline_bend_run=round(float(tip[0] - cl[ib, 0]), 2),
                centreline_bend_drop=round(float(cl[ib, 1] - tip[1]), 2))
    return poly, L, info


def arm_outline():
    run_t, drop_t = ARM_BEND_RUN, ARM_BEND_DROP
    for _ in range(5):                       # correct the bend targets for the height taper
        bend = arm_bend_solve(run_t, drop_t)
        lo, hi = Y_SEAM_TOP + 10.0, Y_REAR + 150.0
        for _ in range(50):
            mid = 0.5 * (lo + hi)
            _, L, _ = arm_outline_and_length(mid, bend)
            if L < ARM_LENGTH:
                lo = mid
            else:
                hi = mid
        poly, L, info = arm_outline_and_length(0.5 * (lo + hi), bend)
        run_t += ARM_BEND_RUN - info['centreline_bend_run']
        drop_t += ARM_BEND_DROP - info['centreline_bend_drop']
    info['hinge_to_tip'] = round(float(L), 1)
    return poly, info


def build_arm_chamfer_cutter(coll, sign=1, lens=False):
    """45-deg chamfer on the arm's outer top edge: ARM_TOP_CHAMFER at the joint (the same
    profile as the hinge cap's rear end), fading out over ARM_CHAMFER_LEN.  Sections are in
    planes of constant y, in the arm plane's (t, z) frame.  lens=True: the short constant
    piece that trims the lens's channel front wall (between cap and arm) to the same profile."""
    y_af = float(y_arm_front(Z_TOP + JOIN_H)[0])
    if lens:
        ys = np.linspace(Y_JOIN - 0.2, y_af - 0.1, 6)
    else:
        ys = np.arange(max(y_af - 1.5, Y_JOIN + 0.1), y_af + ARM_CHAMFER_LEN + 0.5, 0.25)
    c = (ARM_TOP_CHAMFER + 0.2) * (1.0 - smoothstep(y_af + 1.0, y_af + ARM_CHAMFER_LEN, ys)) - 0.2
    zt = z_topline(ys)
    st = np.stack([plane_pt(ys, zt - c - 0.8, 0.8),
                   plane_pt(ys, zt + 0.8, -c - 0.8),
                   plane_pt(ys, zt + 0.8, 0.8)], 1)
    return sweep_obj("tmp_ArmChamfer%+d%s" % (sign, "L" if lens else ""), st, coll, sign)


def build_arms(coll):
    poly, info = arm_outline()
    poly = densify(poly, 1.0, closed=True)
    holes = []
    if has('h'):
        for (y, z) in joint_pin_positions():
            holes.append(plane_circle(y, z, JOINT_PIN_D, JOINT_PIN_SEGS))
    dv, tris = triangulate_domain(poly, holes)
    outer = plane_pt(dv[:, 0], dv[:, 1], 0.0)                 # flush with the panel
    inner = plane_pt(dv[:, 0], dv[:, 1], -ARM_INLAY_T)        # thin where it sits in the channel
    verts, faces = prism_mesh(tris, outer, inner)
    arm_r = make_obj("CoverupArm_R", verts, faces, coll)
    if ARM_T > ARM_INLAY_T:
        # full thickness behind the panel: a step on the hidden inner face only, so the arm
        # still prints flat (outer face down) with no support
        rear = clip_halfplane(poly, np.array([1.0, 0.0]), Y_REAR + ARM_STEP_GAP)
        rear = densify(dedup(rear, 1e-6), 1.0, closed=True)
        dv2, tris2 = triangulate_domain(rear, [])
        v2, f2 = prism_mesh(tris2, plane_pt(dv2[:, 0], dv2[:, 1], -(ARM_INLAY_T - 0.1)),
                            plane_pt(dv2[:, 0], dv2[:, 1], -ARM_T))
        thick = make_obj("tmp_ArmThick", v2, f2, coll)
        bool_apply(arm_r, thick, 'UNION')
        me = thick.data; bpy.data.objects.remove(thick, do_unlink=True); bpy.data.meshes.remove(me)
    if has('e') and ARM_TOP_CHAMFER > 0:
        cut = build_arm_chamfer_cutter(coll)
        bool_apply(arm_r, cut, 'DIFFERENCE')
        me = cut.data; bpy.data.objects.remove(cut, do_unlink=True); bpy.data.meshes.remove(me)
    if ARM_T > ARM_INLAY_T or (has('e') and ARM_TOP_CHAMFER > 0):
        finalize_triangles(arm_r)
        verts = np.array([v.co[:] for v in arm_r.data.vertices])
        faces = [tuple(p.vertices) for p in arm_r.data.polygons]
    vl = verts * np.array([-1.0, 1.0, 1.0])
    faces_l = [tuple(reversed(f)) for f in faces]
    arm_l = make_obj("CoverupArm_L", vl, faces_l, coll)
    info['max_abs_x'] = round(float(np.abs(verts[:, 0]).max()), 3)
    return arm_l, arm_r, info


# =====================================================================================
# SCENE MANAGEMENT
# =====================================================================================
def clear_generated():
    c = bpy.data.collections.get(GEN_COLL)
    if c:
        for ob in list(c.all_objects):
            me = ob.data if ob.type == 'MESH' else None
            bpy.data.objects.remove(ob, do_unlink=True)
            if me is not None and me.users == 0:
                bpy.data.meshes.remove(me)
    for ob in list(bpy.data.objects):
        if ob.name.startswith(("CoverupShades", "SlotCutter", "ShieldPiece", "tmp_")):
            bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)


def shade_auto(ob, angle=35.0):
    """Smooth shading with sharp edges above `angle` (display only, no geometry change)."""
    me = ob.data
    try:
        me.shade_smooth()
        me.set_sharp_from_angle(angle=math.radians(angle))
    except Exception as e:
        for p in me.polygons:
            p.use_smooth = False
        print("shade_auto fallback:", e)


def get_material():
    mat = bpy.data.materials.get("Coverup_DarkGrey")
    if mat is None:
        mat = bpy.data.materials.new("Coverup_DarkGrey")
    mat.use_nodes = True
    bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.035, 0.037, 0.04, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.22
        if "Specular IOR Level" in bsdf.inputs:
            bsdf.inputs["Specular IOR Level"].default_value = 0.6
    mat.diffuse_color = (0.08, 0.085, 0.09, 1.0)
    mat.roughness = 0.25
    return mat


def setup_scene_units():
    us = bpy.context.scene.unit_settings
    us.system = 'METRIC'
    us.scale_length = 0.001
    us.length_unit = 'MILLIMETERS'


def _oblique_ref_placement(behind=250.0):
    """The 3/4 photo sits behind the model on Cam_Oblique's line of sight, facing that
    camera and filling its field of view, so looking through Cam_Oblique overlays it."""
    loc, tgt, lens, sensor, res = MATCH_CAMERAS["Cam_Oblique"]
    C = Vector(loc); f = (Vector(tgt) - C).normalized()
    r = f.cross(Vector((0, 0, 1))).normalized()
    u = r.cross(f)
    dist = (Vector(tgt) - C).length + behind
    size = dist * sensor / lens
    rot = Matrix((r, u, -f)).transposed().to_euler()
    return size, tuple(C + f * dist), tuple(rot)


def setup_refs():
    """Reference image empties at real scale, behind the model, 50% opacity."""
    coll = get_coll(REF_COLL)
    specs = {
        "RefFront": (os.path.join(OUT_DIR, "Reference_Front.jpg"), 149.05,
                     (0.26, 260.0, -0.9), (math.pi / 2, 0.0, 0.0)),
        "RefSide": (os.path.join(OUT_DIR, "Reference_Side.jpg"), 165.9,
                    (-260.0, 81.5, 20.5), (math.pi / 2, 0.0, math.pi / 2)),
        "RefOblique": (os.path.join(OUT_DIR, "Reference_Oblique.png"),) + _oblique_ref_placement(),
    }
    for name, (path, size, loc, rot) in specs.items():
        ob = bpy.data.objects.get(name)
        if ob is None:
            ob = bpy.data.objects.new(name, None)
        for c in list(ob.users_collection):
            if c != coll:
                c.objects.unlink(ob)
        if coll not in ob.users_collection:
            coll.objects.link(ob)
        img = None
        for im in bpy.data.images:
            if im.filepath and os.path.normcase(bpy.path.abspath(im.filepath)) == os.path.normcase(path):
                img = im
        if img is None:
            img = bpy.data.images.load(path)
        else:
            img.reload()
        ob.empty_display_type = 'IMAGE'
        ob.data = img
        ob.empty_display_size = size
        ob.empty_image_offset = (-0.5, -0.5)
        ob.location = loc
        ob.rotation_euler = rot
        ob.use_empty_image_alpha = True
        ob.color[3] = 0.5
        ob.empty_image_depth = 'DEFAULT'
        ob.hide_render = True


# =====================================================================================
# EXPORT
# =====================================================================================
def write_stl(path, ob, M):
    me = ob.data
    me.calc_loop_triangles()
    co = np.empty(len(me.vertices) * 3); me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    co = co @ np.asarray(M)[:3, :3].T + np.asarray(M)[:3, 3]
    tri = np.empty(len(me.loop_triangles) * 3, np.int64)
    me.loop_triangles.foreach_get("vertices", tri)
    tri = tri.reshape(-1, 3)
    v0 = co[tri[:, 0]]; v1 = co[tri[:, 1]]; v2 = co[tri[:, 2]]
    nrm = np.cross(v1 - v0, v2 - v0)
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-30)
    rec = np.zeros(len(tri), dtype=[('n', '<f4', 3), ('v0', '<f4', 3), ('v1', '<f4', 3),
                                    ('v2', '<f4', 3), ('a', '<u2')])
    rec['n'] = nrm; rec['v0'] = v0; rec['v1'] = v1; rec['v2'] = v2
    with open(path, 'wb') as f:
        f.write(b'Coverup shades prop'.ljust(80, b' '))
        f.write(struct.pack('<I', len(tri)))
        f.write(rec.tobytes())
    return co


def print_matrix_lens(ob):
    """Upright, as worn: the lens bottom edge on the bed (see report)."""
    co = np.array([v.co[:] for v in ob.data.vertices])
    M = np.eye(4)
    M[:3, 3] = [-(co[:, 0].max() + co[:, 0].min()) / 2, -(co[:, 1].max() + co[:, 1].min()) / 2, -co[:, 2].min()]
    return M


def print_matrix_arm(ob, sign):
    n = PANEL_N * np.array([sign, 1.0, 1.0])
    e1 = np.array([0.0, 1.0, 0.0]) - n[1] * n
    e1 /= np.linalg.norm(e1)
    e2 = np.cross(-n, e1)
    Rm = np.stack([e1, e2, -n])                       # outer (visible) face down on the bed
    co = np.array([v.co[:] for v in ob.data.vertices]) @ Rm.T
    M = np.eye(4); M[:3, :3] = Rm
    M[:3, 3] = [-(co[:, 0].max() + co[:, 0].min()) / 2, -(co[:, 1].max() + co[:, 1].min()) / 2, -co[:, 2].min()]
    return M


# =====================================================================================
# MATCHED-ANGLE REVIEW RENDERS
# =====================================================================================
# camera: (location, look-at target, focal length mm, sensor width mm, resolution (x, y))
# Fitted to the reference photos; each renders at 2x the photo's pixel size except Oblique.
MATCH_CAMERAS = {
    "Cam_Front":   ((0.26, -1188.4, 61.9), (0.26, 10.0, -0.9), 290.0, 36.0, (1138, 436)),
    "Cam_Side":    ((763.87, 76.42, 193.54), (84.26, 82.15, 25.93), 166.67, 36.0, (1138, 614)),
    "Cam_Oblique": ((-385.48, -398.21, 90.53), (-77.36, -11.97, 13.8), 85.0, 36.0, (1080, 1080)),
    "Cam_Under":   ((-300.0, -500.0, -650.0), (0.0, 40.0, 0.0), 120.0, 36.0, (1200, 900)),
}
MATCH_CAMERAS.update(dict(_G.get("COVERUP_CAMERAS", {}) or {}))
MATCH_FILES = {"Cam_Front": "match_front.png", "Cam_Side": "match_side.png",
               "Cam_Oblique": "match_oblique.png", "Cam_Under": "view_under.png"}


def setup_cameras():
    cams = {}
    for name, (loc, tgt, lens, sensor, res) in MATCH_CAMERAS.items():
        ob = bpy.data.objects.get(name)
        if ob is None:
            cd = bpy.data.cameras.new(name)
            ob = bpy.data.objects.new(name, cd)
            get_coll(REF_COLL).objects.link(ob)
        ob.data.type = 'PERSP'
        ob.data.lens = lens
        ob.data.sensor_fit = 'HORIZONTAL'
        ob.data.sensor_width = sensor
        ob.data.clip_start = 1.0
        ob.data.clip_end = 10000.0
        ob.location = loc
        d = Vector(tgt) - Vector(loc)
        ob.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
        cams[name] = (ob, res)
    return cams


def render_matched(names=None):
    scene = bpy.context.scene
    cams = setup_cameras()
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = next((n for n in world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    old_bg = tuple(bg.inputs[0].default_value) if bg else None
    if bg:
        bg.inputs[0].default_value = (0.92, 0.92, 0.92, 1.0)
        bg.inputs[1].default_value = 1.0
    try:
        scene.render.engine = 'BLENDER_EEVEE'
    except TypeError as e:
        print(e)
    scene.render.film_transparent = False
    scene.view_settings.view_transform = 'Standard'
    scene.render.image_settings.file_format = 'PNG'
    lt = bpy.data.objects.get("Coverup_KeyLight")
    if lt is not None and lt.data.type != 'SUN':
        bpy.data.objects.remove(lt, do_unlink=True)
        lt = None
    if lt is None:
        ld = bpy.data.lights.new("Coverup_KeyLight", 'SUN')
        lt = bpy.data.objects.new("Coverup_KeyLight", ld)
        get_coll(REF_COLL).objects.link(lt)
    lt.data.energy = 3.0
    lt.data.angle = math.radians(25.0)
    lt.location = (-300.0, -700.0, 700.0)
    lt.rotation_euler = (Vector((0, 40, 0)) - lt.location).to_track_quat('-Z', 'Y').to_euler()
    others = [o for o in bpy.data.objects
              if o.name.startswith("Ref") or (o.type == 'LIGHT' and o is not lt)]
    hidden = [(o, o.hide_render) for o in others]
    for o in others:
        o.hide_render = True
    lt.hide_render = False
    old_cam = scene.camera
    old_res = (scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage)
    out = []
    for name, (ob, res) in cams.items():
        if names and name not in names:
            continue
        scene.camera = ob
        scene.render.resolution_x, scene.render.resolution_y = res
        scene.render.resolution_percentage = 100
        scene.render.filepath = os.path.join(RENDER_DIR, MATCH_FILES[name])
        bpy.ops.render.render(write_still=True)
        out.append(scene.render.filepath)
    scene.camera = old_cam
    scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = old_res
    for o, h in hidden:
        o.hide_render = h
    lt.hide_render = True
    if bg and old_bg:
        bg.inputs[0].default_value = old_bg
    return out


# =====================================================================================
# MAIN
# =====================================================================================
def build():
    setup_scene_units()
    clear_generated()
    coll = get_coll(GEN_COLL)
    mat = get_material()
    report = dict(arm_plane_max_dev_mm=round(PLANE_DEV, 3))

    lens, outline, pin_report = build_shell(coll)
    report['shell'] = mesh_report(lens)
    if pin_report:
        report['pinholes'] = pin_report
    tmp = []

    def apply(ob, op):
        tmp.append(ob)
        bool_apply(lens, ob, op)

    if has('b'):
        deck = build_deck(coll)
        report['deck'] = mesh_report(deck)
        apply(deck, 'UNION')
    if has('g'):
        for sign in (1, -1):
            apply(build_joggle_slab(coll, sign), 'UNION')
    if has('b'):
        apply(build_top_cutter(coll), 'DIFFERENCE')
        apply(build_deck_top_cutter(coll), 'DIFFERENCE')
        if BROW_FACET_H > 0:
            apply(build_brow_facet_cutter(coll), 'DIFFERENCE')
    if has('c'):
        apply(build_bottom_cutter(coll), 'DIFFERENCE')
    if has('f'):
        apply(build_pinhole_cutters(coll), 'DIFFERENCE')
    if has('g'):
        for sign in (1, -1):
            apply(build_channel_cutter(coll, sign), 'DIFFERENCE')
    if has('e'):
        if ARM_TOP_CHAMFER > 0:
            for sign in (1, -1):
                apply(build_arm_chamfer_cutter(coll, sign, lens=True), 'DIFFERENCE')
        caps, holes = build_hinge_caps(coll)
        for c in caps:
            apply(c, 'UNION')
        for s in build_seam_cutters(coll):
            apply(s, 'DIFFERENCE')
        for h in holes:
            apply(h, 'DIFFERENCE')
    if has('h'):
        for p in build_joint_pin_cutters(coll):
            apply(p, 'DIFFERENCE')
    for t in tmp:
        me = t.data
        bpy.data.objects.remove(t, do_unlink=True)
        bpy.data.meshes.remove(me)
    report['degenerate_tris_left'] = finalize_triangles(lens)
    lens.data.materials.clear()               # the boolean leaves an empty slot behind
    lens.data.materials.append(mat)
    shade_auto(lens)
    report['lens'] = mesh_report(lens)

    arms = []
    if has('g'):
        arm_l, arm_r, info = build_arms(coll)
        for a in (arm_l, arm_r):
            a.data.materials.clear()
            a.data.materials.append(mat)
            shade_auto(a)
        arms = [arm_l, arm_r]
        report['arm_info'] = info
        report['arm_L'] = mesh_report(arm_l)
        report['arm_R'] = mesh_report(arm_r)

    setup_refs()

    if EXPORT:
        write_stl(os.path.join(OUT_DIR, "coverup_lens.stl"), lens, print_matrix_lens(lens))
        if arms:
            write_stl(os.path.join(OUT_DIR, "coverup_arm_left.stl"), arms[0], print_matrix_arm(arms[0], -1))
            write_stl(os.path.join(OUT_DIR, "coverup_arm_right.stl"), arms[1], print_matrix_arm(arms[1], 1))
    setup_cameras()
    if RENDER:
        report['renders'] = render_matched()
    if EXPORT:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT_DIR, "coverup_shades.blend"), check_existing=False)
        report['exported'] = True
    return report


if not _G.get("COVERUP_NO_BUILD", False):
    REPORT = build()
    for k, v in REPORT.items():
        print(k, ":", v)
