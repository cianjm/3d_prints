/*
Extension lead holder with Pegboard Click rail slots.

Based on Andy Levesque's Underware made-to-measure holder, licensed
Creative Commons 4.0 Attribution-NonCommercial-ShareAlike.
Rail channel measurements and locking profile are carried over from the
Multibin shelf adaptation in this workspace.

Self-contained OpenSCAD source: no external libraries are required.
Units are millimetres.
*/

/* [Mounting Options] */
// Selects the connection profile; slot spacing is selected independently below.
Mounting_Style = "Pegboard Click Rail"; // [Pegboard Click Rail, Multiconnect, Threaded Snap]
// Sets the centre-to-centre mounting grid for every mounting style.
Mounting_Surface = "1-Inch Pegboard"; // [Multiboard, openGrid, 1-Inch Pegboard, Custom]

/* [Custom Mounting Spacing - used only when Mounting Surface is Custom] */
Custom_Distance_Between_Slots = 25;

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

/* [Slot Customization] */
// Applies to Pegboard Click Rail and Multiconnect profiles.
// False: vertical channels, spaced across X using the selected mounting surface.
// True: horizontal channels, spaced across Z using the selected mounting surface.
Rotate_Slots_90_Degrees = false;
// Vertical: true opens at the top, false opens at the bottom.
// Horizontal: true opens at the right, false opens at the left.
Slot_From_Top = true;
// Closed-end offset when clamshell mode is disabled.
Rail_Stop_Distance_From_Edge = 13;
// Multiconnect slot controls retained from the original model.
onRampHalfOffset = true;
slotTolerance = 1.00; // [0.925:0.005:1.075]
dimpleScale = 1; // [0.5:0.05:1.5]
slotDepthMicroadjustment = 0; // [-0.5:0.05:0.5]
onRampEnabled = false;
On_Ramp_Every_X_Slots = 1;
Multiconnect_Stop_Distance_From_Back = 13;
// Clearance PER SIDE around the measured Pegboard Click rail.
railSlotClearance = 0.11; // [0.05:0.01:0.4]
railRecessDepth = 0.80;   // [0:0.05:0.9]
railLockClearance = 0.10; // [0.05:0.05:0.2]
railEndClearance = 2;
slotQuickRelease = false;

/* [Threaded Snap Customization] */
Pitch_Sm = 3;
Outer_Diameter_Sm = 6.747;
Thread_Depth_Sm = 0.5;
Slop = 0.075;

/* [Backer] */
Backer_Only_Mode = false;
// 0 selects 4.8 mm rail, 6.5 mm Multiconnect, or 3.6 mm Threaded Snap.
Force_Back_Thickness = 0;

/* [Hidden] */
epsilon = 0.02;
// Legacy command-line/preset alias retained for backwards compatibility.
Rotate_Rail_Slots_90_Degrees = false;
rotateSlots90 = Rotate_Slots_90_Degrees || Rotate_Rail_Slots_90_Degrees;
// Accept the previous value when supplied with a command-line preset.
railMode = Mounting_Style == "Pegboard Click Rail" ||
    Mounting_Style == "Multipoint - 1 inch Rail";
multiconnectMode = Mounting_Style == "Multiconnect";
threadedSnapMode = Mounting_Style == "Threaded Snap";
mountingStyleValid = railMode || multiconnectMode || threadedSnapMode;
mountingSurfaceValid = Mounting_Surface == "Multiboard" ||
    Mounting_Surface == "openGrid" ||
    Mounting_Surface == "1-Inch Pegboard" ||
    Mounting_Surface == "Custom";
mountingPitch = Mounting_Surface == "Multiboard" ? 25 :
    Mounting_Surface == "openGrid" ? 28 :
    Mounting_Surface == "1-Inch Pegboard" ? 25.4 :
    Custom_Distance_Between_Slots;
totalDepth = Backer_Only_Mode ? Internal_Depth : Internal_Depth+baseThickness;
totalWidth = Backer_Only_Mode ? Internal_Width : Internal_Width+2*wallThickness;
defaultBackThickness = railMode ? 4.8 : threadedSnapMode ? 3.6 : 6.5;
backThickness = Force_Back_Thickness == 0 ? defaultBackThickness : Force_Back_Thickness;
railSlotInset = railRecessDepth;
railBumpProjection = 0.6-railLockClearance;
onRampEveryXSlots = onRampHalfOffset ? On_Ramp_Every_X_Slots :
    On_Ramp_Every_X_Slots == 1 ? 2 : On_Ramp_Every_X_Slots;

mountingWorkSpace = total_item_width+2*baseThickness+2*item_slop-
                    2*Minimum_Safe_Mount_Clearance_From_Edge;
mountPointDistance = floor(mountingWorkSpace/mountingPitch)*mountingPitch;
clamshellStopDistance = (total_item_width-mountPointDistance+
                         2*item_slop+2*baseThickness)/2;
slotStopDistance = ClamShell_Mode ? clamshellStopDistance :
                   Rail_Stop_Distance_From_Edge;
multiconnectStopDistance = ClamShell_Mode ? clamshellStopDistance :
                           Multiconnect_Stop_Distance_From_Back;

assert(Internal_Depth >= 0 && Internal_Width >= 0 && Internal_Height >= 0,
       "Internal dimensions must be nonnegative.");
assert(mountingStyleValid,"Select a supported mounting style.");
assert(mountingSurfaceValid,
       "Select Multiboard, openGrid, 1-Inch Pegboard, or Custom.");
assert(wallThickness >= 0 && baseThickness >= 0,
       "Wall and base thicknesses must be nonnegative.");
assert(!railMode || backThickness >= 3.9,
       "The measured rail channel needs a back at least 3.9 mm thick.");
assert(!railMode || (railSlotClearance >= 0.05 && railSlotClearance <= 0.4),
       "Rail slot clearance must be between 0.05 and 0.4 mm.");
assert(!railMode || (railLockClearance >= 0.05 && railLockClearance <= 0.2),
       "Rail lock clearance must be between 0.05 and 0.2 mm.");
assert(!railMode || (railRecessDepth >= 0 && railRecessDepth <= 0.9),
       "Rail recess depth must be between 0 and 0.9 mm.");
assert(!railMode || railEndClearance >= 0.5,
       "Allow at least 0.5 mm beyond the seated rail.");
assert(!railMode || (rotateSlots90 ? totalWidth : totalDepth) >=
       slotStopDistance+33+railEndClearance,
       str("The 41 mm rail needs at least ",
           slotStopDistance+33+railEndClearance,
           " mm along the channel direction."));

assert(mountingPitch > 0,"Mounting pitch must be positive.");
assert(On_Ramp_Every_X_Slots >= 1 && On_Ramp_Every_X_Slots == floor(On_Ramp_Every_X_Slots),
       "On-ramp frequency must be a positive integer.");

echo(mounting_style=Mounting_Style,
     mounting_surface=Mounting_Surface,
     mounting_pitch_mm=mountingPitch,
     slot_orientation=(railMode || multiconnectMode) ?
        (rotateSlots90 ? "horizontal" : "vertical") : undef);

holder();
if(ClamShell_Mode)
    translate([0,0,total_item_width+2*item_slop])
        mirror([0,0,1]) holder();

module holder() {
    union() {
        if(!Backer_Only_Mode)
            translate([-Internal_Width/2,0,0]) basket();
        mountingBack();
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

module mountingBack() {
    if(railMode)
        railBack();
    else if(multiconnectMode)
        multiconnectBack();
    else if(threadedSnapMode)
        threadedSnapBack();
}

module railBack() {
    backZ0 = -baseThickness;
    patternSpan = rotateSlots90 ? totalDepth : totalWidth;
    slotCount = max(1,floor(patternSpan/mountingPitch));
    firstSlot = (patternSpan-(slotCount-1)*mountingPitch)/2;
    toolY = -2.35+railSlotInset;

    difference() {
        translate([-totalWidth/2,-backThickness,backZ0])
            cube([totalWidth,backThickness+epsilon,totalDepth]);

        for(i=[0:slotCount-1]) {
            p = firstSlot+i*mountingPitch;
            if(rotateSlots90) {
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

module multiconnectBack() {
    backZ0 = -baseThickness;
    patternSpan = rotateSlots90 ? totalDepth : totalWidth;
    slotCount = max(1,floor(patternSpan/mountingPitch));
    firstSlot = (patternSpan-(slotCount-1)*mountingPitch)/2;
    toolY = -2.35+slotDepthMicroadjustment+
            (Force_Back_Thickness == 0 ? 0 : 6.5-backThickness);

    difference() {
        translate([-totalWidth/2,-backThickness,backZ0])
            cube([totalWidth,backThickness+epsilon,totalDepth]);

        for(i=[0:slotCount-1]) {
            p = firstSlot+i*mountingPitch;
            if(rotateSlots90) {
                z = backZ0+p;
                if(Slot_From_Top)
                    translate([-totalWidth/2+multiconnectStopDistance,toolY,z])
                        rotate([0,-90,0]) multiConnectSlotTool(totalWidth);
                else
                    translate([totalWidth/2-multiconnectStopDistance,toolY,z])
                        rotate([0,90,0]) multiConnectSlotTool(totalWidth);
            } else {
                x = -totalWidth/2+p;
                if(Slot_From_Top)
                    translate([x,toolY,backZ0+multiconnectStopDistance])
                        rotate([0,180,0]) multiConnectSlotTool(totalDepth);
                else
                    translate([x,toolY,backZ0+totalDepth-multiconnectStopDistance])
                        multiConnectSlotTool(totalDepth);
            }
        }
    }
}

module multiConnectSlotTool(length) {
    distanceOffset = onRampHalfOffset ? mountingPitch/2 : 0;
    slotProfile = [[0,0],[10.15,0],[10.15,1.2121],
                   [7.65,3.712],[7.65,5],[0,5]];

    scale(slotTolerance)
    difference() {
        union() {
            rotate([90,0,0])
                rotate_extrude($fn=50) polygon(slotProfile);
            rotate([180,0,0])
                linear_extrude(height=length+1)
                    union() {
                        polygon(slotProfile);
                        mirror([1,0,0]) polygon(slotProfile);
                    }
            if(onRampEnabled)
                for(n=[1:onRampEveryXSlots:length/mountingPitch])
                    translate([0,-5,-n*mountingPitch+distanceOffset])
                        rotate([-90,0,0])
                            cylinder(h=5,r1=12,r2=10.15,$fn=50);
        }
        if(!slotQuickRelease)
            scale(dimpleScale)
                rotate([90,0,0])
                    rotate_extrude($fn=50)
                        polygon([[0,0],[0,1.5],[1.5,0]]);
    }
}

module threadedSnapBack() {
    backZ0 = -baseThickness;
    usableWidth = max(0,totalWidth-2*Outer_Diameter_Sm);
    usableHeight = max(0,totalDepth-2*Outer_Diameter_Sm);
    xCount = max(1,floor(usableWidth/mountingPitch)+1);
    zCount = max(1,floor(usableHeight/mountingPitch)+1);
    xFirst = -(xCount-1)*mountingPitch/2;
    zFirst = backZ0+totalDepth/2-(zCount-1)*mountingPitch/2;

    difference() {
        translate([-totalWidth/2,-backThickness,backZ0])
            cube([totalWidth,backThickness+epsilon,totalDepth]);
        for(ix=[0:xCount-1], iz=[0:zCount-1])
            translate([xFirst+ix*mountingPitch,epsilon,
                       zFirst+iz*mountingPitch])
                rotate([90,0,0]) threadedSnapHole(backThickness+2*epsilon);
    }
}

// Self-contained approximation of the original BOSL2 internal trapezoidal thread.
// Nominal diameter, pitch, thread depth and fit slop retain their original controls.
module threadedSnapHole(length) {
    majorRadius = Outer_Diameter_Sm/2+Slop;
    minorRadius = majorRadius-Thread_Depth_Sm;
    slices = max(24,ceil(length/Pitch_Sm*32));

    union() {
        cylinder(h=length,r=minorRadius,$fn=64);
        linear_extrude(height=length,twist=-360*length/Pitch_Sm,
                       slices=slices,convexity=12)
            translate([minorRadius,-Pitch_Sm/4])
                square([majorRadius-minorRadius+epsilon,Pitch_Sm/2]);
        cylinder(h=min(0.6,length),r1=majorRadius+0.4,r2=majorRadius,$fn=64);
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
