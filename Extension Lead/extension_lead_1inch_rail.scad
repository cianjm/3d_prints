/*
Extension lead holder with 1-inch Pegboard Click rail slots.

Based on Andy Levesque's Underware made-to-measure holder, licensed
Creative Commons 4.0 Attribution-NonCommercial-ShareAlike.
Rail channel measurements and locking profile are carried over from the
Multibin shelf adaptation in this workspace.

Self-contained OpenSCAD source: no external libraries are required.
Units are millimetres.
*/

/* [Internal Dimensions] */
Internal_Depth = 50.0;  // Z: usable depth
Internal_Width = 60.0;  // X: usable width
Internal_Height = 15.0; // Y: usable thickness

/* [Holder Style] */
wallThickness = 2;
baseThickness = 3;
edgeRounding = 0.5; // XY-edge rounding

/* [Front Cutout] */
frontCutout = true;
frontLowerCapture = 7;
frontUpperCapture = 0;
frontLateralCapture = 3;

/* [Bottom Cutout] */
bottomCutout = false;
bottomFrontCapture = 3;
bottomBackCapture = 3;
bottomSideCapture = 3;

/* [Cord Cutout] */
cordCutout = false;
cordCutoutDiameter = 10;
cordCutoutLateralOffset = 0;
cordCutoutDepthOffset = 0;

/* [Right Cutout] */
rightCutout = false;
rightLowerCapture = 7;
rightUpperCapture = 0;
rightLateralCapture = 3;

/* [Left Cutout] */
leftCutout = false;
leftLowerCapture = 7;
leftUpperCapture = 0;
leftLateralCapture = 3;

/* [Clamshell Mode] */
ClamShell_Mode = true;
total_item_width = 150;
item_slop = 0.3;
Minimum_Safe_Mount_Clearance_From_Edge = 13;

/* [Rail Slots] */
// False: vertical channels at 25.4 mm spacing across X.
// True: horizontal channels at 25.4 mm spacing across Z.
Rotate_Rail_Slots_90_Degrees = false;
// Vertical: true opens at the top, false opens at the bottom.
// Horizontal: true opens at the right, false opens at the left.
Slot_From_Top = true;
// Closed-end offset when clamshell mode is disabled.
Rail_Stop_Distance_From_Edge = 13;
// Clearance PER SIDE around the measured Pegboard Click rail.
railSlotClearance = 0.11; // [0.05:0.01:0.4]
railRecessDepth = 0.80;   // [0:0.05:0.9]
railLockClearance = 0.10; // [0.05:0.05:0.2]
railEndClearance = 2;
slotQuickRelease = false;

/* [Backer] */
Backer_Only_Mode = false;
Force_Back_Thickness = 0; // 0 uses the measured 4.8 mm rail back

/* [Hidden] */
epsilon = 0.02;
railPitch = 25.4;
totalDepth = Backer_Only_Mode ? Internal_Depth : Internal_Depth+baseThickness;
totalWidth = Backer_Only_Mode ? Internal_Width : Internal_Width+2*wallThickness;
backThickness = Force_Back_Thickness == 0 ? 4.8 : Force_Back_Thickness;
railSlotInset = railRecessDepth;
railBumpProjection = 0.6-railLockClearance;

mountingWorkSpace = total_item_width+2*baseThickness+2*item_slop-
                    2*Minimum_Safe_Mount_Clearance_From_Edge;
mountPointDistance = floor(mountingWorkSpace/railPitch)*railPitch;
clamshellStopDistance = (total_item_width-mountPointDistance+
                         2*item_slop+2*baseThickness)/2;
slotStopDistance = ClamShell_Mode ? clamshellStopDistance :
                   Rail_Stop_Distance_From_Edge;

assert(Internal_Depth >= 0 && Internal_Width >= 0 && Internal_Height >= 0,
       "Internal dimensions must be nonnegative.");
assert(wallThickness >= 0 && baseThickness >= 0,
       "Wall and base thicknesses must be nonnegative.");
assert(backThickness >= 3.9,
       "The measured rail channel needs a back at least 3.9 mm thick.");
assert(railSlotClearance >= 0.05 && railSlotClearance <= 0.4,
       "Rail slot clearance must be between 0.05 and 0.4 mm.");
assert(railLockClearance >= 0.05 && railLockClearance <= 0.2,
       "Rail lock clearance must be between 0.05 and 0.2 mm.");
assert(railRecessDepth >= 0 && railRecessDepth <= 0.9,
       "Rail recess depth must be between 0 and 0.9 mm.");
assert(railEndClearance >= 0.5,
       "Allow at least 0.5 mm beyond the seated rail.");
assert((Rotate_Rail_Slots_90_Degrees ? totalWidth : totalDepth) >=
       slotStopDistance+33+railEndClearance,
       str("The 41 mm rail needs at least ",
           slotStopDistance+33+railEndClearance,
           " mm along the channel direction."));

echo(rail_pitch_mm=railPitch,
     rail_orientation=Rotate_Rail_Slots_90_Degrees ? "horizontal" : "vertical",
     rail_stop_distance_mm=slotStopDistance);

holder();
if(ClamShell_Mode)
    translate([0,0,total_item_width+2*item_slop])
        mirror([0,0,1]) holder();

module holder() {
    union() {
        if(!Backer_Only_Mode)
            translate([-Internal_Width/2,0,0]) basket();
        railBack();
    }
}

module basket() {
    difference() {
        union() {
            translate([-wallThickness,0,-baseThickness])
                roundedXYBox([Internal_Width+2*wallThickness,
                              Internal_Height+wallThickness,
                              baseThickness],edgeRounding);
            translate([-wallThickness,0,0])
                roundedXYBox([wallThickness,Internal_Height+wallThickness,
                              Internal_Depth],edgeRounding);
            translate([Internal_Width,0,0])
                roundedXYBox([wallThickness,Internal_Height+wallThickness,
                              Internal_Depth],edgeRounding);
            translate([0,Internal_Height,0])
                roundedXYBox([Internal_Width,wallThickness,Internal_Depth],
                             edgeRounding);
        }

        if(frontCutout)
            translate([frontLateralCapture,Internal_Height-epsilon,
                       frontLowerCapture])
                cube([Internal_Width-2*frontLateralCapture,
                      wallThickness+2*epsilon,
                      Internal_Depth-frontLowerCapture-frontUpperCapture+epsilon]);
        if(bottomCutout)
            translate([bottomSideCapture,bottomBackCapture,-baseThickness-epsilon])
                cube([Internal_Width-2*bottomSideCapture,
                      Internal_Height-bottomFrontCapture-bottomBackCapture,
                      baseThickness+2*epsilon]);
        if(rightCutout)
            translate([-wallThickness-epsilon,rightLateralCapture,
                       rightLowerCapture])
                cube([wallThickness+2*epsilon,
                      Internal_Height-2*rightLateralCapture,
                      Internal_Depth-rightLowerCapture-rightUpperCapture+epsilon]);
        if(leftCutout)
            translate([Internal_Width-epsilon,leftLateralCapture,
                       leftLowerCapture])
                cube([wallThickness+2*epsilon,
                      Internal_Height-2*leftLateralCapture,
                      Internal_Depth-leftLowerCapture-leftUpperCapture+epsilon]);
        if(cordCutout)
            translate([Internal_Width/2+cordCutoutLateralOffset,
                       Internal_Height/2+cordCutoutDepthOffset,
                       -baseThickness-epsilon]) {
                cylinder(h=baseThickness+frontLowerCapture+2*epsilon,
                         r=cordCutoutDiameter/2,$fn=48);
                translate([-cordCutoutDiameter/2,0,0])
                    cube([cordCutoutDiameter,Internal_Height/2+wallThickness+epsilon,
                          baseThickness+frontLowerCapture+2*epsilon]);
            }
    }
}

module roundedXYBox(size,r) {
    rr = min(max(r,0),min(size[0],size[1])/2-0.001);
    if(rr <= 0)
        cube(size);
    else
        linear_extrude(height=size[2])
            translate([rr,rr]) offset(r=rr,$fn=24)
                square([size[0]-2*rr,size[1]-2*rr]);
}

module railBack() {
    backZ0 = -baseThickness;
    patternSpan = Rotate_Rail_Slots_90_Degrees ? totalDepth : totalWidth;
    slotCount = max(1,floor(patternSpan/railPitch));
    firstSlot = (patternSpan-(slotCount-1)*railPitch)/2;
    toolY = -2.35+railSlotInset;

    difference() {
        translate([-totalWidth/2,-backThickness,backZ0])
            cube([totalWidth,backThickness+epsilon,totalDepth]);

        for(i=[0:slotCount-1]) {
            p = firstSlot+i*railPitch;
            if(Rotate_Rail_Slots_90_Degrees) {
                z = backZ0+p;
                if(Slot_From_Top)
                    translate([-totalWidth/2+slotStopDistance,toolY,z])
                        rotate([0,-90,0]) pegboardRailSlotTool(totalWidth);
                else
                    translate([totalWidth/2-slotStopDistance,toolY,z])
                        rotate([0,90,0]) pegboardRailSlotTool(totalWidth);
            } else {
                x = -totalWidth/2+p;
                if(Slot_From_Top)
                    translate([x,toolY,backZ0+slotStopDistance])
                        rotate([0,180,0]) pegboardRailSlotTool(totalDepth);
                else
                    translate([x,toolY,backZ0+totalDepth-slotStopDistance])
                        pegboardRailSlotTool(totalDepth);
            }
        }
    }
}

module pegboardRailSlotTool(length) {
    difference() {
        pegboardRailChannel(length);
        if(!slotQuickRelease) pegboardRailBumps();
    }
}

module pegboardRailChannel(length) {
    c = railSlotClearance;
    d = 1.216152;
    cutDepth = 2.5+railSlotInset;
    taperEnd = min(cutDepth,2.746152);
    profile = [[0,0],[7.4+c,0],[7.4+c,d],
               [7.4+c-(taperEnd-d),taperEnd],
               [7.4+c-(taperEnd-d),cutDepth],[0,cutDepth]];

    module guide(guideLength) {
        rotate([180,0,0]) linear_extrude(height=guideLength)
            union() {
                polygon(profile);
                mirror([1,0,0]) polygon(profile);
            }
    }

    union() {
        guide(length+1);
        intersection() {
            scale([1/sin(67.5),1,1/sin(67.5)])
                rotate([90,67.5,0])
                    rotate_extrude($fn=8)
                        polygon([[0,0],[8+c,0],[8+c,0.616152],
                                 [8+c-(taperEnd-0.616152),taperEnd],
                                 [8+c-(taperEnd-0.616152),cutDepth],[0,cutDepth]]);
            translate([0,0,10]) guide(20);
        }
    }
}

module pegboardRailBumps() {
    for(side=[-1,1]) scale([side,1,1])
        rotate([90,0,0]) intersection() {
            r = 5.2-railLockClearance;
            a = 1.9+railLockClearance;
            p = railBumpProjection;
            translate([0,0,-epsilon])
                cylinder(h=p+epsilon,r1=r+epsilon,r2=r-p,$fn=64);
            railLoftSection(
                [[a-epsilon,a-epsilon],[6,a-epsilon],[6,6],[a-epsilon,6]],
                [[a+p,a+p],[6,a+p],[6,6],[a+p,6]],-epsilon,p);
        }
}

module railLoftSection(bottom,top,z0,z1) {
    n = len(bottom);
    polyhedron(
        points=concat([for(p=bottom) [p[0],p[1],z0]],
                      [for(p=top) [p[0],p[1],z1]]),
        faces=concat([[for(i=[n-1:-1:0]) i]],
                     [[for(i=[0:n-1]) n+i]],
                     [for(i=[0:n-1]) [i,(i+1)%n,(i+1)%n+n,i+n]]),
        convexity=4);
}
